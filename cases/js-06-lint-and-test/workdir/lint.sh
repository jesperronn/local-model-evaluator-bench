#!/usr/bin/env bash
# Minimal .editorconfig-aware linter. Checks *.js under the project (excluding
# *.test.js and node_modules) against a few common rules. Exits non-zero on any
# violation. Zero dependencies — works with the BSD tools on macOS.
set -uo pipefail
TAB="$(printf '\t')"
ec=".editorconfig"
style="$(sed -nE 's/^[[:space:]]*indent_style[[:space:]]*=[[:space:]]*([a-z]+).*/\1/p' "$ec" 2>/dev/null | head -1)"
trim="$(sed -nE 's/^[[:space:]]*trim_trailing_whitespace[[:space:]]*=[[:space:]]*([a-z]+).*/\1/p' "$ec" 2>/dev/null | head -1)"
finalnl="$(sed -nE 's/^[[:space:]]*insert_final_newline[[:space:]]*=[[:space:]]*([a-z]+).*/\1/p' "$ec" 2>/dev/null | head -1)"

fail=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if [ "${trim:-true}" = true ] && grep -nE ' +$' "$f" >/dev/null 2>&1; then
    echo "lint: trailing whitespace in $f"; fail=1
  fi
  if [ "${style:-space}" = space ] && grep -n "$TAB" "$f" >/dev/null 2>&1; then
    echo "lint: tab used (indent_style=space) in $f"; fail=1
  fi
  if [ "${finalnl:-true}" = true ] && [ -s "$f" ] && [ -n "$(tail -c1 "$f")" ]; then
    echo "lint: missing final newline in $f"; fail=1
  fi
done < <(find . -type f -name '*.js' ! -name '*.test.js' ! -path './node_modules/*')

if [ "$fail" -eq 0 ]; then echo "lint: clean"; fi
exit "$fail"
