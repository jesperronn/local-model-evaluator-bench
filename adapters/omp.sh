#!/usr/bin/env bash
# Adapter: omp (oh-my-pi) -> any local runtime, addressed by provider prefix.
#
# NOT routed through the LiteLLM proxy — omp has its own provider system
# (~/.omp/agent/models.yml, YAML, not JSON) with lms/omlx/mtplx/mlx registered
# as distinct custom providers pointing directly at each runtime's own port
# (see docs/MODEL-DISCOVERY.md's "omp (oh-my-pi)" section for why: omp's
# built-in "lm-studio" provider does LM-Studio-specific discovery that these
# runtimes don't implement, and sharing one provider slot across runtimes
# caused mtplx/omlx to clobber each other's cached model). The provider names
# below just happen to match this file's --provider values.
#
# Model IDs are prefixed by provider: lms/<id>, ollama/<id>, omlx/<id>, mlx/<id>, mtplx/<id>
#
# Adapter accepts --provider to override which backend to target:
#   --provider lms        # route to LM Studio (default if lms/ prefix)
#   --provider ollama     # route to Ollama
#   --provider omlx       # route to oMLX
#   --provider mlx        # route to mlx_lm.server
#   --provider mtplx      # route to MTPLX
#
# Install: npm install -g <omp-package>
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"

MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"
PROVIDER="${PROVIDER:-lms}"

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

command -v omp >/dev/null 2>&1 || {
  echo "omp not found; install: npm install -g <omp-package>" >&2
  exit 1
}

# Prefix the model ID with the provider name if not already prefixed.
# This allows both "lms/model-id" and separate --provider flag to work.
if [[ "$MODEL_ID" =~ ^(lms|ollama|mlx|omlx|mtplx|openai)/ ]]; then
  # Already has a provider prefix, use as-is
  PREFIXED_MODEL_ID="$MODEL_ID"
else
  # Add the provider prefix based on --provider flag
  PREFIXED_MODEL_ID="${PROVIDER}/${MODEL_ID}"
fi

OMP_ARGS=(--model "$PREFIXED_MODEL_ID")

if [ ! -t 0 ]; then
  exec omp "${OMP_ARGS[@]}" -p "$(cat)"
else
  exec omp "${OMP_ARGS[@]}" "$@"
fi
