#!/usr/bin/env bash
# bin/lib/agent-settings.test.sh — unit tests for the config-writer helpers.
# Direct-execution: bin/lib/agent-settings.test.sh  (or via bin/test)
set -uo pipefail
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
source "$HERE/bin/lib/agent-settings.sh"

if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
  C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
else C_GRN=; C_RED=; C_RST=; fi
pass=0; fail=0
check() { # desc expected actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MJS="$HERE/bin/lib/patch-jsonc-models.mjs"

# ── yaml_upsert_flat ─────────────────────────────────────────────────────────
printf 'model: old\nother: keep\n' > "$TMP/a.yaml"
out="$(yaml_upsert_flat model NEW < "$TMP/a.yaml")"
check "flat: replaces existing key" "model: NEW
other: keep" "$out"
check "flat: preserves other keys" "keep" "$(printf '%s\n' "$out" | yaml_get_flat other)"

out="$(printf 'x: 1\n' | yaml_upsert_flat model NEW)"
check "flat: appends missing key" "x: 1
model: NEW" "$out"

# idempotent
out1="$(yaml_upsert_flat model NEW < "$TMP/a.yaml")"
out2="$(printf '%s\n' "$out1" | yaml_upsert_flat model NEW)"
check "flat: idempotent" "$out1" "$out2"

# URL value with slashes/colons survives
out="$(printf 'openai-api-base: old\n' | yaml_upsert_flat openai-api-base 'http://localhost:1234/v1')"
check "flat: url value intact" "openai-api-base: http://localhost:1234/v1" "$out"

# ── yaml_set_nested / yaml_get_nested (hermes-shaped, 4-space indent) ─────────
cat > "$TMP/h.yaml" <<'EOF'
approvals:
    mode: smart
auxiliary:
    guardian:
        api: http://should-not-change/v1
        api_key: leave-me
providers:
    lmstudio:
        api: http://127.0.0.1:1234/v1
        api_key: old-key
        default_model: foo
    ollama:
        api: http://127.0.0.1:11434/v1
EOF
before_lines=$(wc -l < "$TMP/h.yaml")
out="$(yaml_set_nested providers lmstudio api 'http://localhost:1234/v1' '    ' < "$TMP/h.yaml" \
      | yaml_set_nested providers lmstudio api_key 'lm-studio' '    ')"
printf '%s\n' "$out" > "$TMP/h2.yaml"
check "nested: lmstudio.api replaced" "http://localhost:1234/v1" "$(yaml_get_nested providers lmstudio api '    ' < "$TMP/h2.yaml")"
check "nested: lmstudio.api_key replaced" "lm-studio" "$(yaml_get_nested providers lmstudio api_key '    ' < "$TMP/h2.yaml")"
check "nested: unrelated auxiliary.guardian.api untouched" "1" "$(grep -c 'http://should-not-change/v1' "$TMP/h2.yaml")"
check "nested: auxiliary.guardian.api_key untouched" "1" "$(grep -c 'api_key: leave-me' "$TMP/h2.yaml")"
check "nested: ollama.api untouched" "1" "$(grep -c 'http://127.0.0.1:11434/v1' "$TMP/h2.yaml")"
check "nested: line count unchanged (replace-only)" "$before_lines" "$(wc -l < "$TMP/h2.yaml")"
# exactly two lines differ
ndiff=$(diff "$TMP/h.yaml" "$TMP/h2.yaml" | grep -c '^[<>]')
check "nested: exactly two lines changed" "4" "$ndiff"  # 2 old + 2 new in diff output
# missing key → no change
out="$(yaml_set_nested providers lmstudio nonesuch VALUE '    ' < "$TMP/h.yaml")"
check "nested: missing leaf leaves file unchanged" "$(cat "$TMP/h.yaml")" "$out"

# ── mjs set/get (opencode JSONC, comment-safe) ───────────────────────────────
cat > "$TMP/oc.jsonc" <<'EOF'
{
  // keep this comment
  "model": "lmstudio/old",
  "provider": {
    "lmstudio": {
      "options": { "baseURL": "http://old/v1" },
      "models": { "a": { "name": "A" } }
    },
    "mlx": { "options": { "baseURL": "http://mlx" } }
  }
}
EOF
check "mjs: get scalar" "http://old/v1" "$(jsonc_get "$TMP/oc.jsonc" provider.lmstudio.options.baseURL)"
node "$MJS" set "$TMP/oc.jsonc" \
  provider.lmstudio.options.baseURL '"http://new/v1"' \
  provider.lmstudio.options.apiKey  '"lm-studio"' \
  model '"lmstudio/new"' > "$TMP/oc2.jsonc"
check "mjs: baseURL replaced" "http://new/v1" "$(jsonc_get "$TMP/oc2.jsonc" provider.lmstudio.options.baseURL)"
check "mjs: apiKey inserted" "lm-studio" "$(jsonc_get "$TMP/oc2.jsonc" provider.lmstudio.options.apiKey)"
check "mjs: top-level model replaced" "lmstudio/new" "$(jsonc_get "$TMP/oc2.jsonc" model)"
check "mjs: comment preserved" "1" "$(grep -c 'keep this comment' "$TMP/oc2.jsonc")"
check "mjs: other provider untouched" "1" "$(grep -c 'http://mlx' "$TMP/oc2.jsonc")"
check "mjs: models block untouched" "1" "$(grep -c '"name": "A"' "$TMP/oc2.jsonc")"
# idempotent set
node "$MJS" set "$TMP/oc2.jsonc" provider.lmstudio.options.baseURL '"http://new/v1"' > "$TMP/oc3.jsonc"
check "mjs: set idempotent" "$(cat "$TMP/oc2.jsonc")" "$(cat "$TMP/oc3.jsonc")"

# ── json_set (pi jq) ─────────────────────────────────────────────────────────
cat > "$TMP/pi.json" <<'EOF'
{ "providers": { "lmstudio": { "baseUrl": "http://old/v1", "apiKey": "x", "models": [] } }, "model": "keep" }
EOF
out="$(json_set "$TMP/pi.json" '.providers.lmstudio.baseUrl=$u|.providers.lmstudio.apiKey=$k' --arg u 'http://new/v1' --arg k 'lm-studio')"
check "json_set: baseUrl" "http://new/v1" "$(printf '%s' "$out" | jq -r '.providers.lmstudio.baseUrl')"
check "json_set: default model untouched" "keep" "$(printf '%s' "$out" | jq -r '.model')"

# ── commit_if_changed ────────────────────────────────────────────────────────
printf 'hello\n' > "$TMP/c.txt"
o="$(printf 'hello\n' | commit_if_changed "$TMP/c.txt" "c" 1)"
check "commit: no-op when identical" "c: up to date" "$o"
printf 'world\n' | commit_if_changed "$TMP/c.txt" "c" 1 >/dev/null
check "commit: writes on change" "world" "$(cat "$TMP/c.txt")"
check "commit: backup created" "1" "$(ls "$TMP"/c.txt.bak.* 2>/dev/null | wc -l | tr -d ' ')"
rm -f "$TMP/new.txt"
printf 'seed\n' | commit_if_changed "$TMP/new.txt" "new" 1 >/dev/null
check "commit: creates missing file" "seed" "$(cat "$TMP/new.txt")"
# dry-run does not write
printf 'orig\n' > "$TMP/d.txt"
printf 'changed\n' | commit_if_changed "$TMP/d.txt" "d" 0 >/dev/null
check "commit: dry-run leaves file" "orig" "$(cat "$TMP/d.txt")"

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
