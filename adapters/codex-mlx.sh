#!/usr/bin/env bash
# Adapter: codex -> mlx_lm.server.
# mlx_lm.server only implements /v1/chat/completions, not /v1/responses.
# The global ~/.codex/config.toml has wire_api="responses" which can't be
# overridden via -c flags. We use CODEX_HOME to point at a temp dir containing
# a minimal config.toml with wire_api="chat-completions".
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"
export LMS_API_KEY

# Build a throw-away CODEX_HOME with just the wire_api override.
_codex_home="$(mktemp -d)"
cat > "$_codex_home/config.toml" <<TOML
wire_api = "chat-completions"
model = "$MODEL_ID"
model_provider = "mlx_local"

[model_providers.mlx_local]
name = "MLX"
base_url = "$LMS_BASE_URL"
env_key = "LMS_API_KEY"
TOML

CODEX_HOME="$_codex_home" exec codex exec \
  --skip-git-repo-check \
  --dangerously-bypass-approvals-and-sandbox \
  "$PROMPT"
