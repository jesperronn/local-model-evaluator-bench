#!/usr/bin/env bash
# bin/stale.test.sh — verify bin/stale's missing/failed/stale classification.
# Builds a throwaway repo layout in a tmpdir and drives bin/stale against it via
# the STALE_* override hooks. Run directly: bin/stale.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
STALE="$HERE/bin/stale"

C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- fake repo layout --------------------------------------------------------
mkdir -p "$TMP/adapters" "$TMP/cases/c1/workdir" "$TMP/results"
: > "$TMP/config.sh"; : > "$TMP/common.sh"; : > "$TMP/bench"; : > "$TMP/shim"
echo 'echo hi' > "$TMP/adapters/aider-lms.sh"
echo 'echo hi' > "$TMP/adapters/pi-lms.sh"
echo '{"id":"c1"}' > "$TMP/cases/c1/meta.json"
echo 'task' > "$TMP/cases/c1/task.md"
echo 'x' > "$TMP/cases/c1/workdir/f.txt"
printf 'm1\n' > "$TMP/models.txt"

# Backdate every input so a result run timestamped "now-ish" looks newer.
OLD='200001010000'  # touch -t stamp: 2000-01-01
touch -t "$OLD" "$TMP/config.sh" "$TMP/common.sh" "$TMP/bench" "$TMP/shim" \
  "$TMP/adapters/aider-lms.sh" "$TMP/adapters/pi-lms.sh" \
  "$TMP/cases/c1/meta.json" "$TMP/cases/c1/task.md" "$TMP/cases/c1/workdir/f.txt"

# A prior run from 2020 with: aider ok, pi error(1).
RUN="$TMP/results/20200101-120000"
mkdir -p "$RUN"
cat > "$RUN/results.csv" <<EOF
adapter,model,case,pass,total,score,seconds,status,trials,runtime
aider,m1,c1,1,1,1.00,10,ok,1,lms
pi,m1,c1,0,1,0.00,10,error(1),1,lms
EOF

run_stale() {  # extra args -> CSV stdout only (stderr discarded)
  STALE_RESULTS_DIR="$TMP/results" STALE_CASES_DIR="$TMP/cases" \
  STALE_ADAPTERS_DIR="$TMP/adapters" STALE_MODELS_FILE="$TMP/models.txt" \
  STALE_CONFIG_SH="$TMP/config.sh" STALE_COMMON_SH="$TMP/common.sh" \
  STALE_BENCH="$TMP/bench" STALE_SHIM="$TMP/shim" \
  bash "$STALE" --agent aider,pi --cases c1 "$@" 2>/dev/null
}

# 1. Baseline: aider is ok+current -> skipped; pi failed -> emitted as failed.
out="$(run_stale)"
check "ok+current combo is skipped"      ""                       "$(grep '^aider,' <<<"$out")"
check "failed combo is emitted"          "pi,m1,c1,lms,failed(error(1))" "$(grep '^pi,' <<<"$out")"

# 2. Touch aider's adapter to "now" -> aider becomes stale.
touch "$TMP/adapters/aider-lms.sh"
out="$(run_stale)"
check "touched adapter -> stale"         "aider,m1,c1,lms,stale"  "$(grep '^aider,' <<<"$out")"

# 3. --failed-only suppresses the stale aider row, keeps pi.
out="$(run_stale --failed-only)"
check "--failed-only drops stale"        ""                       "$(grep '^aider,' <<<"$out")"
check "--failed-only keeps failed"       "pi,m1,c1,lms,failed(error(1))" "$(grep '^pi,' <<<"$out")"

# 4. Unknown model not in results -> missing for both adapters.
out="$(run_stale --model m2 --missing-only)"
check "never-run combo -> missing"       "aider,m2,c1,lms,missing" "$(grep '^aider,m2' <<<"$out")"

# 5. Global input (config.sh) touched -> even an ok combo goes stale.
touch -t "$OLD" "$TMP/adapters/aider-lms.sh"   # reset adapter to old first
touch "$TMP/config.sh"
out="$(run_stale --stale-only)"
check "touched config.sh -> aider stale" "aider,m1,c1,lms,stale"  "$(grep '^aider,' <<<"$out")"

echo
if [ "$fail" -eq 0 ]; then echo "${C_GRN}all $pass passed${C_RST}"; exit 0
else echo "${C_RED}$fail failed${C_RST}, $pass passed"; exit 1; fi
