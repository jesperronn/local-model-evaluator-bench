#!/usr/bin/env bash
# Singleton manager for codex-models-wrapper.py
# Ensures only ONE wrapper instance runs, shared by all concurrent codex.sh invocations.
#
# Usage:
#   port=$(adapters/codex-wrapper-manager.sh start <target_url>)
#   adapters/codex-wrapper-manager.sh stop
#
# The manager ref-counts users:
# - Each "start" increments the ref count and ensures the wrapper is running
# - Each "stop" decrements the ref count and kills the wrapper when count reaches 0
# This prevents premature termination when multiple codex.sh invocations run concurrently.

set -euo pipefail

ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SCRIPT="$ADAPTER_DIR/codex-models-wrapper.py"
WRAPPER_PORT=19900
WRAPPER_HOST="127.0.0.1"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
STATE_FILE="$STATE_DIR/codex-wrapper-manager.state"
LOCK_FILE="$STATE_DIR/codex-wrapper-manager.lock"

# Helper: acquire a lock for coordinating between concurrent invocations (uses mkdir for atomicity)
_lock() {
  local timeout=5
  while ! mkdir "$LOCK_FILE" 2>/dev/null; do
    if [[ $timeout -le 0 ]]; then
      echo "Warning: Failed to acquire lock after 5s" >&2
      return 1
    fi
    sleep 0.1
    ((timeout--))
  done
}

_unlock() {
  rmdir "$LOCK_FILE" 2>/dev/null || true
}

# Check if the wrapper is actually listening (pure bash, no external deps)
_wrapper_is_running() {
  # Try to connect to the wrapper port; if successful, it's running
  timeout 0.5 bash -c "exec 3<>/dev/tcp/$WRAPPER_HOST/$WRAPPER_PORT && exec 3>&- && exec 3<&-" 2>/dev/null && return 0 || return 1
}

# Start the wrapper if not already running
_ensure_wrapper_running() {
  local target_url="$1"
  local ref_count=1

  if [[ -f "$STATE_FILE" ]]; then
    local pid=$(grep "^PID=" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    ref_count=$(grep "^REF_COUNT=" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "0")

    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && _wrapper_is_running; then
      # Wrapper is already running and healthy, just increment ref count
      ((ref_count++))
      awk -v rc="$ref_count" '/^REF_COUNT=/{print "REF_COUNT=" rc; next} 1' "$STATE_FILE" >"${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      return 0
    fi
    # Stale PID or wrapper not responsive, clean up
  fi

  # Start the wrapper (redirect output to /dev/null so it doesn't block)
  python3 "$WRAPPER_SCRIPT" "$WRAPPER_PORT" "$target_url" >/dev/null 2>&1 &
  local new_pid=$!

  # Write state with ref count = 1
  mkdir -p "$(dirname "$STATE_FILE")"
  cat >"$STATE_FILE" <<EOF
PID=$new_pid
REF_COUNT=1
TARGET_URL=$target_url
TIMESTAMP=$(date +%s)
EOF

  # Wait for wrapper to be ready
  local retries=10
  while [[ $retries -gt 0 ]]; do
    if _wrapper_is_running; then
      return 0
    fi
    sleep 0.1
    ((retries--))
  done

  echo "Failed to start codex-models-wrapper on port $WRAPPER_PORT" >&2
  kill "$new_pid" 2>/dev/null || true
  rm -f "$STATE_FILE"
  return 1
}

case "${1:-}" in
  start)
    if [[ -z "${2:-}" ]]; then
      echo "Usage: $0 start <target_url>" >&2
      exit 1
    fi

    _lock
    _ensure_wrapper_running "$2"
    _unlock

    # Return the port so codex.sh can use it
    echo "$WRAPPER_PORT"
    ;;

  stop)
    _lock
    if [[ -f "$STATE_FILE" ]]; then
      ref_count=$(grep "^REF_COUNT=" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "1")
      ((ref_count--))

      if [[ $ref_count -le 0 ]]; then
        # Last user exiting, kill the wrapper
        pid=$(grep "^PID=" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
          kill "$pid" 2>/dev/null || true
          sleep 0.1
          kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$STATE_FILE"
      else
        # Other users still running, just decrement ref count
        awk -v rc="$ref_count" '/^REF_COUNT=/{print "REF_COUNT=" rc; next} 1' "$STATE_FILE" >"${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
      fi
    fi
    _unlock
    ;;

  *)
    echo "Usage: $0 [start <target_url> | stop]" >&2
    exit 1
    ;;
esac
