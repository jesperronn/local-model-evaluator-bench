#!/usr/bin/env bash
# Adapter: cline -> unified endpoint via LiteLLM proxy.
# Routes through the LiteLLM proxy ($LITELLM_BASE_URL) to any local runtime
# (lms, ollama, mlx, omlx, mtplx) based on model ID prefix.
#
# The proxy must be running: bin/litellm-proxy start
# Model IDs are prefixed by provider: lms/<id>, ollama/<id>, omlx/<id>, mlx/<id>, mtplx/<id>
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
#   --provider mtplx      # route to MTPLX
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
PROVIDER="${PROVIDER:-${RUNTIME:-lms}}"

# Parse --provider flag if passed
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Resolve the cline binary, falling back to the pnpm store when PATH is broken.
if ! cline --version >/dev/null 2>&1; then
  CLINE=$(find /Users/jesper/Library/pnpm/store -name "cline" \
    -path "*/cli-darwin-arm64/bin/cline" 2>/dev/null | sort --version-sort --reverse | head -1)
  [ -x "${CLINE:-}" ] || { echo "cline not found; reinstall: pnpm install -g cline" >&2; exit 1; }
else
  CLINE=cline
fi

# Prefix the model ID with the provider name if not already prefixed.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# Configure cline to use the litellm proxy for all backends
DATA_DIR="$HOME/.cline-litellm-adapter"
"$CLINE" auth openai-compatible \
  --data-dir "$DATA_DIR" \
  --apikey  "${LITELLM_MASTER_KEY:-litellm}" \
  --modelid "$PREFIXED_MODEL_ID" \
  --baseurl "$LITELLM_BASE_URL" >/dev/null 2>&1

CLINE_ARGS=(
  --data-dir "$DATA_DIR"
  -P "openai-compatible"
  --model "$PREFIXED_MODEL_ID"
)

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
