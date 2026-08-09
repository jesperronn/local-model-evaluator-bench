#!/usr/bin/env bash
# bin/check-model-discovery.test.sh — verify bin/check-model-discovery against
# fixture cards. Network-dependent --check-upstream behavior is exercised only
# against a fake `curl`/API shim, never the real GitHub API, so this test runs
# fully offline.
# Run directly: bin/check-model-discovery.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$HERE/bin/check-model-discovery"

if [ -z "${NO_COLOR:-}" ]; then
  C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
else
  C_GRN=; C_RED=; C_RST=
fi
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/tools"

# --- a tool card with a filled-in, non-placeholder row -----------------------
cat > "$TMP/tools/good.md" <<'EOF'
# good

## Metadata

| Field | Value |
|-------|-------|
| **Adapter script** | [`adapters/good-lms.sh`](../../adapters/good-lms.sh) |
| **Runtime model discovery** | **no** — `--model "$MODEL_ID"` is passed explicitly; no discovery call is made. |
EOF

# --- a tool card that documents an adapter but has no row at all -------------
cat > "$TMP/tools/missing-row.md" <<'EOF'
# missing-row

## Metadata

| Field | Value |
|-------|-------|
| **Adapter script** | [`adapters/missing-row-lms.sh`](../../adapters/missing-row-lms.sh) |
| **How it connects** | some backend |
EOF

# --- a tool card with an empty/placeholder row -------------------------------
cat > "$TMP/tools/placeholder.md" <<'EOF'
# placeholder

## Metadata

| Field | Value |
|-------|-------|
| **Adapter script** | [`adapters/placeholder-lms.sh`](../../adapters/placeholder-lms.sh) |
| **Runtime model discovery** | TODO |
EOF

# --- a doc with no adapter at all (should be skipped, not flagged) -----------
cat > "$TMP/tools/no-adapter.md" <<'EOF'
# no-adapter

Just a utility doc, not an agent harness card. No Metadata table at all.
EOF

run() { CHECK_MODEL_DISCOVERY_TOOLS_DIR="$TMP/tools" "$CHECK" --card "$1"; }

run "$TMP/tools/good.md" >/dev/null 2>&1
check "conforming card passes" "0" "$?"

run "$TMP/tools/missing-row.md" >/dev/null 2>&1
check "card with adapter but no row fails" "1" "$?"

missing_msg="$(run "$TMP/tools/missing-row.md" 2>&1 | grep -c "missing 'Runtime model discovery' row")"
check "missing-row failure message present" "1" "$missing_msg"

run "$TMP/tools/placeholder.md" >/dev/null 2>&1
check "card with placeholder row fails" "1" "$?"

placeholder_msg="$(run "$TMP/tools/placeholder.md" 2>&1 | grep -c "empty or a placeholder")"
check "placeholder failure message present" "1" "$placeholder_msg"

run "$TMP/tools/no-adapter.md" >/dev/null 2>&1
check "non-adapter doc without the row is not flagged" "0" "$?"

# --- whole-directory run: exit 1 overall because of the bad fixtures --------
CHECK_MODEL_DISCOVERY_TOOLS_DIR="$TMP/tools" "$CHECK" >/dev/null 2>&1
check "directory-wide run fails when any card fails" "1" "$?"

# --- real docs/tools/*.md must all currently pass lint (no network) ---------
"$CHECK" >/dev/null 2>&1
check "real docs/tools cards all pass lint" "0" "$?"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
