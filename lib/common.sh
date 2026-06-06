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

# List model ids currently *loaded* in LM Studio (from the OpenAI endpoint).
lms_loaded_models() {
  curl -fsS --max-time 5 "$LMS_BASE_URL/models" 2>/dev/null \
    | grep -oE '"id"\s*:\s*"[^"]+"' \
    | sed -E 's/.*"id"\s*:\s*"([^"]+)".*/\1/'
}
