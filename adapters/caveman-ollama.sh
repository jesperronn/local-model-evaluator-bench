#!/usr/bin/env bash
# Adapter: caveman -> Ollama.
# Status: UNSUPPORTED — caveman-code (npm) does not support local Ollama provider.
#
# The npm caveman-code binary does not recognize "ollama" as a valid provider.
# It only works with cloud providers (Anthropic, OpenAI, etc.) via environment variables.
#
# To enable this adapter, either:
#   (a) npm caveman-code adds ollama-provider support (check caveman-code issues)
#   (b) use pi-ollama instead (pi has full ollama support via ~/.pi/agent/models.json)
set -euo pipefail

cat >&2 <<'EOF'
Error: Unknown provider "ollama". Use --list-models to see available providers/models.
The installed caveman-code (npm) does not support local providers.
It only works with cloud providers (Anthropic, OpenAI, etc.) via environment variables.

See adapters/caveman-ollama.sh for details.
EOF

exit 1
