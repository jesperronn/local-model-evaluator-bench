#!/usr/bin/env bash
# Adapter: caveman -> LM Studio.
# Tool: caveman-code (npm, unknown version), 2026-06-28
# Status: UNSUPPORTED — caveman-code (npm) does not support local LM Studio provider.
#
# The npm caveman-code binary does not read ~/.pi/agent/models.json and only
# supports cloud providers via environment variables (ANTHROPIC_API_KEY,
# OPENAI_API_KEY, etc.). This adapter was written for the pi-based caveman
# which had custom-provider support.
#
# To enable this adapter, either:
#   (a) npm caveman-code adds custom-provider support (check caveman-code issues)
#   (b) reinstall pi-based build with custom provider mechanism
set -euo pipefail

cat >&2 <<'EOF'
Error: caveman adapter for LM Studio is not supported.
The installed caveman-code (npm) does not support local providers.
It only works with cloud providers (Anthropic, OpenAI, etc.) via environment variables.

See adapters/caveman-lms.sh for details.
EOF

exit 1
