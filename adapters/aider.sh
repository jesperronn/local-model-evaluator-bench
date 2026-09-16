#!/usr/bin/env bash
# Adapter: aider -> unified endpoint via LiteLLM proxy.
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
# Contract: CWD is the sandbox to edit. $MODEL_ID set.
# Non-interactive (piped stdin): prompt arrives on stdin, one-shot.
# Interactive (stdin is a tty): drops into a real aider REPL.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-${RUNTIME:-lms}}"

declare -a REMAINING_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)    MODEL_ID="$2"; shift 2;;
    --provider) PROVIDER="$2"; shift 2;;
    *)          REMAINING_ARGS+=("$1"); shift;;
  esac
done

command -v aider >/dev/null 2>&1 || {
  echo "aider not found; install: pip install aider-chat" >&2
  exit 1
}

# Determine which runtime to use based on model prefix or naming.
# aider uses OpenAI-compatible endpoints via --openai-api-base/--openai-api-key.
# NOTE: aider bundles litellm client-side, which REQUIRES a provider prefix
# (openai/, ollama/, etc.) to parse the model name, even for direct endpoints.
if [[ "$MODEL_ID" =~ ^omlx/ ]] || [[ "$MODEL_ID" == "Ornith"* ]]; then
  API_BASE="$OMLX_BASE_URL"
  API_KEY="$OMLX_API_KEY"
  # Strip omlx/ prefix if present, then wrap in openai/ for litellm parser
  PREFIXED_MODEL_ID="openai/${MODEL_ID#omlx/}"
elif [[ "$MODEL_ID" =~ ^lms/ ]]; then
  API_BASE="$LMS_BASE_URL"
  API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="openai/${MODEL_ID#lms/}"
elif [[ "$LITELLM_PROXY_MODE" == "1" ]]; then
  API_BASE="$LITELLM_BASE_URL"
  API_KEY="$LITELLM_MASTER_KEY"
  # Prefix the model ID for litellm proxy
  if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
    PREFIXED_MODEL_ID="$MODEL_ID"
  else
    PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
  fi
  # Wrap in openai/ for aider's litellm client check
  if [[ ! "$PREFIXED_MODEL_ID" =~ ^openai/ ]]; then
    PREFIXED_MODEL_ID="openai/${PREFIXED_MODEL_ID}"
  fi
else
  # Default to LMS when proxy disabled
  API_BASE="$LMS_BASE_URL"
  API_KEY="$LMS_API_KEY"
  PREFIXED_MODEL_ID="openai/${MODEL_ID}"
fi

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

# Runtime-specific flags: mtplx models sometimes struggle with whole-file format,
# especially on single-line edits. Use diff format for more reliable edit output.
if [[ "$PROVIDER" == "mtplx" ]]; then
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
