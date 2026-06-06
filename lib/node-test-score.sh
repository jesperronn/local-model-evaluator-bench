#!/usr/bin/env bash
# lib/node-test-score.sh <test-glob...>
# Runs Node's built-in test runner (zero install; works for .js and .ts via
# Node 24 type-stripping) and prints a single line: RESULT pass=N total=N
# Test files are expected alongside, importing the model-edited source.
set -uo pipefail

out="$(node --test --test-reporter=tap "$@" 2>&1)" ; echo "$out" >&2  # full output to stderr
total="$(printf '%s\n' "$out" | sed -nE 's/^# tests ([0-9]+)/\1/p' | tail -1)"
pass="$(printf '%s\n'  "$out" | sed -nE 's/^# pass ([0-9]+)/\1/p'  | tail -1)"
total="${total:-0}"; pass="${pass:-0}"
echo "RESULT pass=${pass} total=${total}"
