#!/usr/bin/env bash
# Adapter: cline -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($EP_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching and no per-runtime endpoint selection are
# needed here (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id.
#
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
#
# Known model incompatibilities (revisit when adapter/model updates):
#   nvidia/nemotron-3-nano-omni  — cline 3.0.31, 2026-06-28
#     Model passes wrong shape to `read_files` (array of strings instead of
#     array of objects). It self-corrects on the next turn but loses turns to
#     the retry; smoke-01-edit-file still PASSed in run 20260628-073902.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

# Resolve the cline binary, falling back to the pnpm store when PATH is broken.
if ! cline --version >/dev/null 2>&1; then
  CLINE=$(find /Users/jesper/Library/pnpm/store -name "cline" \
    -path "*/cli-darwin-arm64/bin/cline" 2>/dev/null | sort --version-sort --reverse | head -1)
  [ -x "${CLINE:-}" ] || { echo "cline not found; reinstall: pnpm install -g cline" >&2; exit 1; }
else
  CLINE=cline
fi

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
API_BASE="$EP_URL"
API_KEY="$EP_KEY"

# Configure cline to use Olla
DATA_DIR="$HOME/.cline-local-adapter"
"$CLINE" auth openai-compatible \
  --data-dir "$DATA_DIR" \
  --apikey  "$API_KEY" \
  --modelid "$BARE_MODEL_ID" \
  --baseurl "$API_BASE" >/dev/null 2>&1

CLINE_ARGS=(
  --data-dir "$DATA_DIR"
  -P "openai-compatible"
  --model "$BARE_MODEL_ID"
)

# Ornith-specific optimization: reduce verbose reasoning output
# Only apply --thinking=low to Ornith models; other models may not support it
if [[ "$BARE_MODEL_ID" =~ ornith|Ornith ]]; then
  CLINE_ARGS+=(--thinking low)
fi

if [ ! -t 0 ]; then
  # Suppress AI SDK warnings that cline writes to stdout (not stderr) on first
  # invocation. Without this, the deprecation warning corrupts </tool_call>
  # into </tool_AI SDK Warning...call>, breaking the XML match below.
  export AI_SDK_LOG_WARNINGS=false
  # Fix malformed tool calls from weak models like google/gemma-4-e4b.
  # Converts: <tool_call>\neditor{new_text:"...",path:"..."}\n</tool_call>
  # To: [editor] {"path":"...","new_text":"..."}
  "$CLINE" "${CLINE_ARGS[@]}" "$(cat)" | perl -0777 -pe '
    s|<tool_call>\s*([a-z_]+)\s*\{([^}]+)\}\s*</tool_call>|
      my $func = $1; my $args = $2;
      $args =~ s/([a-z_]+):/"$1":/g;
      "[$func] {$args}"
    |gse
  '
else
  exec "$CLINE" "${CLINE_ARGS[@]}" --tui
fi
