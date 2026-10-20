#!/usr/bin/env bash
# bin/timeout.test.sh — hard-timeout regression: a fake agent that sleeps past a
# short ceiling and spawns a child must be killed (whole tree) within
# timeout+grace. No real model involved. Also covers the sleep-aware clock and
# the wait_hard_ceiling backstop when timeout(1) is a no-op passthrough.
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/lib/common.sh"
if [ -z "${NO_COLOR:-}" ]; then C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'; else C_GRN=; C_RED=; C_RST=; fi
pass=0; fail=0
check() {  # desc expected actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Fake adapter: spawns a long-lived child (records its pid), then sleeps itself.
cat >"$TMP/fake.sh" <<EOS
#!/usr/bin/env bash
sleep 300 & echo \$! >"$TMP/child.pid"
sleep 300
EOS

alive() { kill -0 "$1" 2>/dev/null && echo alive || echo dead; }

# 1) run_timeout (real timeout(1)) kills agent + child; rc 124.
start=$(date +%s)
( run_timeout 5 bash "$TMP/fake.sh" ) & wp=$!
wait "$wp"; rc=$?; el=$(( $(date +%s) - start ))
check "run_timeout exits 124" 124 "$rc"
check "run_timeout returns within timeout+grace" yes "$([ "$el" -le 25 ] && echo yes || echo "no(${el}s)")"
sleep 1
check "run_timeout child killed" dead "$(alive "$(cat "$TMP/child.pid")")"

# 2) Backstop alone: shadow timeout/gtimeout with a passthrough that never enforces.
mkdir -p "$TMP/fakebin"
for t in timeout gtimeout; do
  printf '#!/bin/sh\nwhile [ "${1#-}" != "$1" ]; do shift; done\nshift\nexec "$@"\n' >"$TMP/fakebin/$t"
  chmod +x "$TMP/fakebin/$t"
done
rm -f "$TMP/child.pid"
start=$(date +%s)
( PATH="$TMP/fakebin:$PATH" run_timeout 5 bash "$TMP/fake.sh" ) & wp=$!
wait_hard_ceiling "$wp" "$start" 5 3; rc=$?
wait "$wp" 2>/dev/null
el=$(( $(date +%s) - start ))
check "backstop reports 124 when timeout(1) is a no-op" 124 "$rc"
check "backstop fires within timeout+grace" yes "$([ "$el" -le 20 ] && echo yes || echo "no(${el}s)")"
sleep 1
check "backstop kills wrapper" dead "$(alive "$wp")"
check "backstop kills child process" dead "$(alive "$(cat "$TMP/child.pid")")"

# 3) Sleep-aware clock: a simulated 100s gap is excluded from awake time.
hc_init 2; HC_LAST=$(( $(date +%s) - 100 )); hc_tick
check "hc_tick records suspend gap" yes "$([ "$HC_SLEPT" -ge 95 ] && [ "$HC_SLEPT" -le 100 ] && echo yes || echo "no($HC_SLEPT)")"
check "hc_active excludes sleep" yes "$([ "$(hc_active $(( $(date +%s) - 100 )))" -le 5 ] && echo yes || echo no)"
hc_init 2; HC_LAST=$(( $(date +%s) - 3 )); hc_tick
check "normal tick gap not counted as sleep" 0 "$HC_SLEPT"

echo; echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
