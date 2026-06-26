# lib/grader.sh — shared helpers for case graders (source from check/run.sh).
#
# Per-check decomposition contract: a grader emits, for every atomic check,
# one machine line on STDOUT:
#     CHECK <pass|fail> <id...>
# alongside the human "ok:/MISS:" line on STDERR, and finally the authoritative
# aggregate on STDOUT:
#     RESULT pass=N total=N
# bin/bench records each CHECK row to results/<run>/checks.csv so you can see
# WHICH sub-step a given model failed — not just the aggregate score. The RESULT
# line stays authoritative for scoring; CHECK lines are diagnostic.
#
# Usage:
#   source "$REPO_ROOT/lib/grader.sh"
#   check_eq "top 3"  "$expected" "$got"      # pass iff equal
#   if [ -f x ]; then check_pass "x exists"; else check_fail "x exists"; fi
#   node ... | tap_to_checks                  # turn TAP into CHECK lines
#   emit_result                               # prints RESULT from the tally
#
# IDs may contain spaces; bin/bench replaces commas so the CSV stays clean.

_G_PASS=0; _G_TOTAL=0

check_pass() { _G_PASS=$((_G_PASS+1)); _G_TOTAL=$((_G_TOTAL+1)); echo "  ok: ${2:-$1}" >&2; echo "CHECK pass $1"; }
check_fail() {                       _G_TOTAL=$((_G_TOTAL+1)); echo "  MISS: ${2:-$1}" >&2; echo "CHECK fail $1"; }

# check_eq <id> <expected> <actual>: pass iff the two strings are equal.
check_eq() {
  if [ "$2" = "$3" ]; then check_pass "$1"
  else check_fail "$1" "$1 -- expected [$2] got [$3]"; fi
}

# tap_to_checks: read Node --test TAP on stdin, emit one CHECK line per test.
# (Subtest nesting is flattened; diagnostic only, so an exact count match with
# RESULT's total is not required.)
tap_to_checks() {
  sed -nE \
    -e 's/^[[:space:]]*not ok [0-9]+ - (.*)$/CHECK fail \1/p' \
    -e 's/^[[:space:]]*ok [0-9]+ - (.*)$/CHECK pass \1/p'
}

emit_result() { echo "RESULT pass=${_G_PASS} total=${_G_TOTAL}"; }
