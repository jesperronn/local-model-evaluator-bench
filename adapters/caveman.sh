#!/usr/bin/env bash
# Adapter: caveman -> unified endpoint via provider routing.
# Routes to different local runtimes (lms, ollama, mlx, omlx, mtplx) based on
# the --provider flag or MODEL_ID prefix.
#
# Adapter accepts --provider to select which backend to target:
#   --provider lms        # route to LM Studio
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # skip (caveman doesn't support mlx_lm.server)
#   --provider mtplx      # skip (caveman doesn't support MTPLX)
#
# Install: npm install -g @juliusbrussee/caveman-code
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-lms}"

# Parse --provider flag if passed
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

command -v caveman >/dev/null 2>&1 || {
  echo "caveman not found; install: npm install -g @juliusbrussee/caveman-code" >&2
  exit 1
}

# Validate provider and ensure config exists
case "$PROVIDER" in
  lms|ollama|omlx)
    CAVE_LIVE_CFG="$HOME/.cave/agent/models.json"
    if [ ! -f "$CAVE_LIVE_CFG" ] || ! jq -e ".providers.$PROVIDER" "$CAVE_LIVE_CFG" >/dev/null 2>&1; then
      echo "warn: $CAVE_LIVE_CFG missing a $PROVIDER provider — copying config-templates/caveman-agent-models.json" >&2
      mkdir -p "$(dirname "$CAVE_LIVE_CFG")"
      cp "$REPO_ROOT/config-templates/caveman-agent-models.json" "$CAVE_LIVE_CFG"
    fi
    ;;
  mlx)
    if [ ! -t 0 ]; then cat > /dev/null; fi  # drain stdin when piped
    echo "caveman: skipped — caveman built-in model list required; MLX model IDs not supported" >&2
    exit 1
    ;;
  mtplx)
    if [ ! -t 0 ]; then cat > /dev/null; fi  # drain stdin when piped
    echo "caveman: skipped — MTPLX not supported by caveman" >&2
    exit 1
    ;;
  *)
    if [ ! -t 0 ]; then cat > /dev/null; fi  # drain stdin when piped
    echo "caveman: unknown provider '$PROVIDER' (valid: lms, ollama, omlx)" >&2
    exit 1
    ;;
esac

CAVEMAN_ARGS=(--provider "$PROVIDER" --model "$MODEL_ID")

if [ ! -t 0 ]; then
  exec caveman "${CAVEMAN_ARGS[@]}" --print "$(cat)"
else
  exec caveman "${CAVEMAN_ARGS[@]}" "$@"
fi
