#!/usr/bin/env bash
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0
fail=0

check() {
  local name="$1"; shift
  if "$@"; then
    printf '[PASS] %s\n' "$name"
    pass=$((pass + 1))
  else
    printf '[FAIL] %s\n' "$name"
    fail=$((fail + 1))
  fi
}

has_common_source() {
  rg -q 'source .*lib/common\.sh' "$1"
}

has_palette_use() {
  rg -q 'C_(RED|GRN|YEL|BLU|DIM|BLD|RST)' "$1"
}

has_no_unconditional_ansi() {
  ! rg -n '\\033' "$1" >/dev/null
}

for script in hwprofile litellm-proxy monitor-inference verify-model-availability troubleshoot; do
  check "bin/$script uses shared color palette" has_common_source "$HERE/bin/$script"
  check "bin/$script applies palette tokens" has_palette_use "$HERE/bin/$script"
done

check "service/pass-through utilities remain uncolored" bash -c '! rg -n "C_(RED|GRN|YEL|BLU|DIM|BLD|RST)|NO_COLOR" "$0" "$1" >/dev/null' "$HERE/bin/tool-call-proxy" "$HERE/bin/xxc"

check "bin/pi-patch-edit-shim has a TTY-aware color helper" rg -q 'process\.stdout\.isTTY|NO_COLOR' "$HERE/bin/pi-patch-edit-shim"
check "bin/trace-tool-calls has a TTY-aware color helper" rg -q 'sys\.stdout\.isatty|NO_COLOR' "$HERE/bin/trace-tool-calls"
check "bin/trace-tool-calls colors verdict statuses" rg -q 'verdict_color|VERDICT_COLOR' "$HERE/bin/trace-tool-calls"
check "bin/lms_gc uses shared palette" has_common_source "$HERE/bin/lms_gc"
check "bin/lms_gc has no unconditional ANSI definitions" has_no_unconditional_ansi "$HERE/bin/lms_gc"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
(( fail == 0 ))
