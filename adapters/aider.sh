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

# Prefix the model ID with the provider name if not already prefixed.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

# aider bundles its own litellm client-side to parse --model before any network
# call is made. It only recognizes litellm's built-in provider registry, so our
# runtime prefixes (omlx/, mtplx/, ...) throw `LLM Provider NOT provided` before
# --openai-api-base is ever consulted. litellm always recognizes "openai/" and,
# for that provider, treats everything after the first slash as an opaque model
# id it forwards verbatim — so wrapping the already-prefixed id in another
# "openai/" layer satisfies aider's client-side check while still sending our
# original runtime-prefixed id (e.g. "omlx/<model>") on the wire, which is what
# config-templates/litellm.yaml's wildcard routes match on server-side.
if [[ ! "$PREFIXED_MODEL_ID" =~ ^openai/ ]]; then
  PREFIXED_MODEL_ID="openai/${PREFIXED_MODEL_ID}"
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
  --openai-api-base "$LITELLM_BASE_URL"
  --openai-api-key "${LITELLM_MASTER_KEY:-litellm}"
  --no-check-update --no-show-model-warnings --no-gitignore
  --yes-always --no-auto-commits --no-dirty-commits
)

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
# aider can work without explicit file list for one-shot prompts
if [ "$INTERACTIVE" != 1 ]; then
  # Batch mode: skip files (message is piped, context is minimal)
  exec aider "${AIDER_ARGS[@]}" "${REMAINING_ARGS[@]}"
else
  # Interactive mode: provide all files for context
  exec aider "${AIDER_ARGS[@]}" "${FILES[@]}" "${REMAINING_ARGS[@]}"
fi
