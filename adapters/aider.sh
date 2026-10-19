#!/usr/bin/env bash
# Adapter: aider -> unified endpoint via Olla proxy (OpenAI format).
# Routes ONLY through Olla ($OLLA_BASE_URL) — see docs/runtimes/olla.md
# "Adapter wiring" for the pattern this adapter follows. Olla auto-discovers
# every backend's models (omlx, mtplx, lms, ollama) under one unified list,
# so no runtime-prefix branching and no per-runtime endpoint selection are
# needed here (unlike the old LiteLLM-routed version of this file).
#
# Olla must be running: bin/rt olla start
# $MODEL_ID may be passed bare or with a runtime prefix (omlx/<id>, etc.) —
# strip_runtime_prefix (lib/common.sh) strips it, since Olla addresses models
# by their own bare id. NOTE: aider bundles litellm client-side, which
# REQUIRES a provider prefix (openai/, ...) to parse the model name even for
# a direct OpenAI-compatible endpoint, so the bare id is still re-wrapped in
# "openai/" below — that has nothing to do with the old LiteLLM proxy.
#
# Contract: CWD is the sandbox to edit. $MODEL_ID set.
# Non-interactive (piped stdin): prompt arrives on stdin, one-shot.
# Interactive (stdin is a tty): drops into a real aider REPL.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

declare -a REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)    MODEL_ID="$2"; shift 2;;
    *)          REMAINING_ARGS+=("$1"); shift;;
  esac
done

command -v aider >/dev/null 2>&1 || {
  echo "aider not found; install: pip install aider-chat" >&2
  exit 1
}

adapter_endpoint || exit 1

BARE_MODEL_ID="$(strip_runtime_prefix "$MODEL_ID")"
API_BASE="$EP_URL"
API_KEY="$EP_KEY"
# aider's bundled litellm client requires a provider prefix to parse the
# model name, even though the endpoint is a direct OpenAI-compatible one.
PREFIXED_MODEL_ID="openai/${BARE_MODEL_ID}"

# Interactive callers get a real aider REPL; batch callers pass the prompt on stdin.
INTERACTIVE=0
MESSAGE=""
if [ -t 0 ]; then
  INTERACTIVE=1
else
  MESSAGE=$(cat)
  if [ -z "$MESSAGE" ]; then
    cat >&2 <<EOF
Error: aider adapter requires input text (prompt) on stdin.

Next steps:
  1. For testing: pipe a prompt via stdin:
     echo "your prompt" | adapters/aider.sh

  2. For interactive work, run without piping input:
     adapters/aider.sh
EOF
    exit 1
  fi
fi

AIDER_ARGS=(
  --model "${PREFIXED_MODEL_ID}"
  --openai-api-base "$API_BASE"
  --openai-api-key "$API_KEY"
  --no-check-update --no-show-model-warnings --no-gitignore
  --yes-always --no-auto-commits --no-dirty-commits
)

# mtplx models sometimes struggle with whole-file format, especially on
# single-line edits. Use diff format for more reliable edit output.
if [[ "$BARE_MODEL_ID" =~ ^mtplx- ]] || [[ "$MODEL_ID" =~ ^mtplx/ ]]; then
  AIDER_ARGS+=(--edit-format diff)
fi

[ "$INTERACTIVE" = 1 ] || AIDER_ARGS+=(--message "$MESSAGE")

# Pass the sandbox's source files so aider has context for edit cases.
declare -a FILES=()
if [ "$INTERACTIVE" != 1 ]; then
  mapfile -t FILES < <(find . -type f \
    -not -path './.git/*' \
    -not -name '.*' \
    -not -name '*.log' \
    2>/dev/null | sort)
fi

# For batch mode with many files, limit to avoid argument overflow
# aider needs explicit file list to properly track and edit files in batch mode
if [ "$INTERACTIVE" != 1 ]; then
  # Batch mode: pass files so aider can track them for edits
  exec aider "${AIDER_ARGS[@]}" "${FILES[@]}" "${REMAINING_ARGS[@]}"
else
  # Interactive mode: provide all files for context
  exec aider "${AIDER_ARGS[@]}" "${FILES[@]}" "${REMAINING_ARGS[@]}"
fi
