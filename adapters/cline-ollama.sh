#!/usr/bin/env bash
# Adapter: cline -> Ollama.
# Uses cline's built-in "ollama" provider (no base URL override needed;
# defaults to localhost:11434). Writes an isolated data-dir so this adapter
# does not touch ~/.cline settings.
# NOTE: pnpm global install is broken (global/v11 missing). The adapter falls
# back to the latest cli-darwin-arm64 binary found in the pnpm store.
# Fix permanently with: pnpm install -g cline
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
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

DATA_DIR="$HOME/.cline-ollama-adapter"
# auth initialises the SQLite DBs and writes providers.json in one step.
# Ollama doesn't use a real key; "ollama" is a required placeholder.
# ollama provider uses localhost:11434 by default; --baseurl is not supported.
"$CLINE" auth ollama \
  --data-dir "$DATA_DIR" \
  --apikey  "ollama" \
  --modelid "$MODEL_ID" >/dev/null 2>&1

CLINE_ARGS=(
  --data-dir "$DATA_DIR"
  -P ollama
  --model "$MODEL_ID"
)

if [ ! -t 0 ]; then
  exec "$CLINE" "${CLINE_ARGS[@]}" "$(cat)"
else
  exec "$CLINE" "${CLINE_ARGS[@]}" --tui
fi
