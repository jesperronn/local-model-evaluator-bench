#!/usr/bin/env bash
# bin/lint.test.sh — verify bin/lint runs shellcheck-based checks with no
# external services (no SONAR_URL/SONAR_TOKEN required).
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$HERE/bin/lint"

# Colors (disabled if NO_COLOR is set).
if [ -z "${NO_COLOR:-}" ]; then
  C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
else
  C_GRN=; C_RED=; C_RST=
fi
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n    expected: %s\n    actual:   %s\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}
contains() {  # desc  haystack  needle
  case "$2" in *"$3"*) printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1));;
    *) printf '%s %s\n    wanted substring: %s\n    in: %s\n' "${C_RED}[FAIL]${C_RST}" "$1" "$3" "$2"; fail=$((fail+1));; esac
}

# 1. Runs with SONAR_URL/SONAR_TOKEN unset (the regression this fixes).
out=$(env -u SONAR_URL -u SONAR_TOKEN NO_COLOR=1 "$LINT" "$HERE/bin/lint" 2>&1); rc=$?
check "clean file passes without SONAR_URL" "0" "$rc"
contains "reports clean result" "$out" "clean"

# 2. Help works and mentions no sonar dependency.
out=$(NO_COLOR=1 "$LINT" --help 2>&1); rc=$?
check "--help exits 0" "0" "$rc"
contains "help documents shellcheck usage" "$out" "shellcheck"

# 3. Unknown option is rejected.
out=$(NO_COLOR=1 "$LINT" --bogus 2>&1); rc=$?
check "unknown option exits non-zero" "2" "$rc"

# 4. A file with a syntax error fails.
tmp="$(mktemp -t lint-bad-XXXX.sh)"
printf '#!/usr/bin/env bash\nif [ 1 = 1 ' > "$tmp"   # unterminated if
out=$(NO_COLOR=1 "$LINT" "$tmp" 2>&1); rc=$?
rm -f "$tmp"
check "syntax error exits non-zero" "1" "$rc"

echo ""
total=$((pass+fail))
echo "Results: $pass/$total passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
