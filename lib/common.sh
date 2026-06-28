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
# --kill-after=15: send SIGKILL 15s after SIGTERM so tools waiting on a slow
# API call don't exceed the time limit.
run_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout --kill-after=15 "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout --kill-after=15 "$secs" "$@"
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
  lms ps --json 2>/dev/null | jq -r '.[].modelKey'
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

# Filter adapters to exclude those marked as broken in compat.json.
# Usage: filter_broken_adapters <adapters_csv> <model> <runtime>
# Returns comma-separated list of working adapters (or original if no compat.json).
filter_broken_adapters() {
  local adapters_csv="$1" model="$2" runtime="$3"
  local compat_file="${REPO_ROOT}/compat.json"

  [ -f "$compat_file" ] || { echo "$adapters_csv"; return 0; }
  [ -z "$adapters_csv" ] && return 0

  local result=()
  IFS=',' read -ra adapter_arr <<< "$adapters_csv"

  for adapter in "${adapter_arr[@]}"; do
    local compat_key="${adapter}:${model}:${runtime}"
    local status
    status="$(jq -r --arg k "$compat_key" '.[$k].status // "none"' "$compat_file" 2>/dev/null || echo "none")"

    # Skip if status is "open" (broken); include if "resolved", "none", or jq fails
    if [ "$status" != "open" ]; then
      result+=("$adapter")
    fi
  done

  printf '%s' "$(IFS=','; printf '%s' "${result[*]}")"
}

# Pretty-print adapters filtered out due to known incompatibilities.
# Usage: warn_filtered_adapters <original_csv> <filtered_csv> <model> <runtime>
warn_filtered_adapters() {
  local orig="$1" filtered="$2" model="$3" runtime="$4"
  local compat_file="${REPO_ROOT}/compat.json"

  [ -f "$compat_file" ] || return 0

  # Find which adapters were filtered
  IFS=',' read -ra orig_arr <<< "$orig"
  IFS=',' read -ra filt_arr <<< "$filtered"

  declare -A filt_set
  for a in "${filt_arr[@]}"; do filt_set[$a]=1; done

  local skipped=()
  for a in "${orig_arr[@]}"; do
    [ -z "${filt_set[$a]:-}" ] && skipped+=("$a")
  done

  if [ ${#skipped[@]} -gt 0 ]; then
    warn "skipping ${#skipped[@]} adapter(s) with known incompatibilities for $model on $runtime:"
    for a in "${skipped[@]}"; do
      local compat_key="${a}:${model}:${runtime}"
      local symptom
      symptom="$(jq -r --arg k "$compat_key" '.[$k].symptom // ""' "$compat_file" 2>/dev/null)"
      if [ -n "$symptom" ]; then
        echo "      ${C_DIM}${a}: ${symptom:0:100}${C_RST}"
      else
        echo "      ${C_DIM}${a}${C_RST}"
      fi
    done
  fi
}
