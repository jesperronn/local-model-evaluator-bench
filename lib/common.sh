# lib/common.sh — helpers shared by bin/ scripts and adapters.
# Source after config.sh.

# Colors (disabled if not a TTY).
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
  C_BLU=$'\033[34m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'; C_BLD=$'\033[1m'
else
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_DIM=; C_RST=; C_BLD=
fi

info()  { printf '%s\n' "${C_BLU}==>${C_RST} $*"; }
ok()    { printf '%s\n' "${C_GRN}[PASS]${C_RST} $*"; }
warn()  { printf '%s\n' "${C_YEL}[WARN]${C_RST} $*" >&2; }
err()   { printf '%s\n' "${C_RED}[FAIL]${C_RST} $*" >&2; }
die()   { err "$*"; exit 1; }

# Read non-comment, non-blank lines from a file into stdout.
read_list() {
  grep -vE '^\s*(#|$)' "$1" 2>/dev/null || true
}

# Reachability check against the LM Studio server. Returns 0 if up.
lms_up() {
  curl -fsS --max-time 5 "$LMS_BASE_URL/models" >/dev/null 2>&1
}

# Portable timeout: run_timeout <seconds> <cmd...>. Uses GNU timeout if present,
# else falls back to perl's alarm (ships with macOS). Exit 124 on timeout.
run_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"
  else perl -e 'my $s=shift; $SIG{ALRM}=sub{exit 124}; alarm $s; exec @ARGV or exit 127' "$secs" "$@"
  fi
}

# Sanitize a model id into a filesystem-safe path segment.
fs_safe() { printf '%s' "$1" | tr '/:' '__'; }

# Median of the numeric args. Odd count: the middle value. Even count: the mean
# of the two middle values. Empty input prints 0. Used to collapse repeated
# trials (--trials N) into one robust per-(tool,model,case) number, since
# run-to-run variance makes a single trial untrustworthy.
median() {
  [ $# -gt 0 ] || { printf '0'; return; }
  printf '%s\n' "$@" | sort -n | awk '
    { a[NR]=$1 }
    END {
      m=int(NR/2)
      if (NR%2) print a[m+1]
      else      printf "%.4f", (a[m]+a[m+1])/2
    }'
}

# Model ids currently LOADED in memory (from `lms ps`, the authoritative source).
# Note: the OpenAI /v1/models endpoint lists ALL downloaded models (JIT load),
# so it can't tell us what's resident — `lms ps` can.
lms_loaded_models() {
  lms ps --json 2>/dev/null \
    | grep -oE '"modelKey":"[^"]+"' \
    | sed -E 's/.*:"([^"]+)"/\1/'
}

# Ensure a model is resident. Idempotent; tolerates stale identifiers.
# Usage: ensure_model_loaded <model-key> [ttl-seconds] [context-length]
ensure_model_loaded() {
  local m="$1" ttl="${2:-}" ctx="${3:-}" ttl_arg=() ctx_arg=()
  lms_loaded_models | grep -qxF "$m" && return 0
  [ -n "$ttl" ] && ttl_arg=(--ttl "$ttl")
  [ -n "$ctx" ] && ctx_arg=(-c "$ctx")
  if lms load "$m" --yes "${ttl_arg[@]}" "${ctx_arg[@]}" >/dev/null 2>/tmp/.lmsload.err; then return 0; fi
  # Stale identifier left from a prior --identifier load: clear and retry once.
  if grep -qi "already" /tmp/.lmsload.err; then
    lms unload "$m" >/dev/null 2>&1 || true
    lms load "$m" --yes "${ttl_arg[@]}" "${ctx_arg[@]}" >/dev/null 2>&1 && return 0
  fi
  return 1
}
