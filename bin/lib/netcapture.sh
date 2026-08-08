# lib/netcapture.sh — capture outbound network calls made by a short-lived
# adapter invocation. Implements the "Method that worked" from
# docs/HANDOFF-phone-home-audit.md:
#   1. lsof-poll loop while the adapter's job is running, to catch any
#      ESTABLISHED/SYN_SENT socket to a non-loopback remote (IP only).
#   2. A local CONNECT-logging proxy (HTTP_PROXY/HTTPS_PROXY) run alongside,
#      to recover the SNI hostname lsof can't see.
#   3. Cached whois org lookup per remote IP, so repeated runs against the
#      same cloud provider don't re-shell out to whois every time.
#
# Source after lib/common.sh. Requires: lsof, python3, whois (optional —
# missing whois degrades to "org unknown", not a hard failure).

NETCAP_WHOIS_CACHE_DIR="${NETCAP_WHOIS_CACHE_DIR:-$HOME/.cache/phone-home-audit}"
NETCAP_WHOIS_CACHE="${NETCAP_WHOIS_CACHE:-$NETCAP_WHOIS_CACHE_DIR/whois-cache.tsv}"
mkdir -p "$NETCAP_WHOIS_CACHE_DIR" 2>/dev/null || true
touch "$NETCAP_WHOIS_CACHE" 2>/dev/null || true

# whois org for an IP, cached on disk (ip<TAB>org) across runs.
netcap_whois_org() {
  local ip="$1" cached org
  cached="$(awk -F'\t' -v ip="$ip" '$1==ip{print $2; exit}' "$NETCAP_WHOIS_CACHE" 2>/dev/null)"
  if [ -n "$cached" ]; then printf '%s\n' "$cached"; return 0; fi
  if ! command -v whois >/dev/null 2>&1; then printf '%s\n' "unknown (no whois)"; return 0; fi
  org="$(whois "$ip" 2>/dev/null | grep -iE '^(orgname|org-name|owner|netname|descr):' | head -1 \
    | sed -E 's/^[^:]+:[[:space:]]*//')"
  [ -z "$org" ] && org="unknown"
  printf '%s\t%s\n' "$ip" "$org" >> "$NETCAP_WHOIS_CACHE"
  printf '%s\n' "$org"
}

# Start a local CONNECT-logging stub proxy on 127.0.0.1:$1, logging every
# "CONNECT host:port" line to $2. Runs for at most $3 seconds. Sets
# NETCAP_PROXY_PID. Non-blocking (backgrounds itself).
netcap_proxy_start() {
  local port="$1" logfile="$2" max_seconds="${3:-30}"
  : > "$logfile"
  python3 -c '
import socket, threading, time, sys
port = int(sys.argv[1]); logfile = sys.argv[2]; max_seconds = float(sys.argv[3])
def handle(conn):
    try:
        data = conn.recv(4096).decode(errors="replace")
        first = data.splitlines()[0] if data else ""
        with open(logfile, "a") as f:
            f.write(first + "\n")
    except Exception:
        pass
    try:
        conn.sendall(b"HTTP/1.1 502 Bad Gateway\r\n\r\n"); conn.close()
    except Exception:
        pass
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", port)); s.listen(50)
end = time.time() + max_seconds
while time.time() < end:
    s.settimeout(1)
    try:
        conn, _ = s.accept()
    except socket.timeout:
        continue
    threading.Thread(target=handle, args=(conn,), daemon=True).start()
' "$port" "$logfile" "$max_seconds" &
  NETCAP_PROXY_PID=$!
}

netcap_proxy_stop() {
  [ -n "${NETCAP_PROXY_PID:-}" ] && kill "$NETCAP_PROXY_PID" 2>/dev/null
  wait "$NETCAP_PROXY_PID" 2>/dev/null || true
  NETCAP_PROXY_PID=""
}

# Run a command (as a background job) for up to $duration seconds, polling
# `lsof -i` on every PID matching $pgrep_pattern every 0.2s, appending
# non-LISTEN lines to $hits_file. Blocks until the job finishes or the
# duration elapses, then kills anything still matching the pattern.
#
# Usage: netcap_watch <duration_seconds> <pgrep_pattern> <hits_file> -- cmd...
netcap_watch() {
  local duration="$1" pattern="$2" hits_file="$3"
  shift 3
  [ "$1" = "--" ] && shift
  : > "$hits_file"
  ("$@") &
  local jobpid=$!
  local elapsed=0
  while kill -0 "$jobpid" 2>/dev/null; do
    for p in $(pgrep -f "$pattern" 2>/dev/null); do
      lsof -a -p "$p" -i -P 2>/dev/null | grep -v LISTEN >> "$hits_file" 2>/dev/null
    done
    sleep 0.2
    elapsed=$(awk -v e="$elapsed" 'BEGIN{printf "%.1f", e+0.2}')
    if awk -v e="$elapsed" -v d="$duration" 'BEGIN{exit !(e>=d)}'; then
      kill "$jobpid" 2>/dev/null
      break
    fi
  done
  wait "$jobpid" 2>/dev/null
  # Clean up any straggler process the adapter spawned (e.g. the node CLI
  # itself, once its parent shell job is killed).
  pkill -f "$pattern" 2>/dev/null || true
}

# Extract unique non-loopback remote IPs from an lsof-hits file. lsof -i -P
# lines look like: "node    1234 user  20u  IPv4 ...  TCP 127.0.0.1:54321->161.117.125.9:443 (ESTABLISHED)"
netcap_remote_ips() {
  local hits_file="$1"
  grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}:[0-9]+->[0-9]{1,3}(\.[0-9]{1,3}){3}:[0-9]+' "$hits_file" 2>/dev/null \
    | sed -E 's/.*->([0-9.]+):[0-9]+/\1/' \
    | grep -vE '^(127\.|0\.0\.0\.0$)' \
    | sort -u
}

# Extract unique hostnames from a CONNECT-proxy log (lines: "CONNECT host:port HTTP/1.1").
netcap_connect_hosts() {
  local logfile="$1"
  grep -oE '^CONNECT [^ ]+' "$logfile" 2>/dev/null \
    | awk '{print $2}' | sed -E 's/:[0-9]+$//' | sort -u
}
