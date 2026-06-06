#!/usr/bin/env bash
# Adapter: codex -> LM Studio.
# Codex talks to any OpenAI-compatible endpoint via a custom model_provider.
# We pass the provider definition inline with -c overrides so no edit to
# ~/.codex/config.toml is required. See docs/SETUP.md for the persistent setup.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

export LMS_API_KEY  # codex reads the key from this env var (see -c env_key).

exec codex exec \
  --skip-git-repo-check \
  --dangerously-bypass-approvals-and-sandbox \
  -c model="$MODEL_ID" \
  -c model_provider="lmstudio" \
  -c model_providers.lmstudio.name="LM Studio" \
  -c model_providers.lmstudio.base_url="$LMS_BASE_URL" \
  -c model_providers.lmstudio.env_key="LMS_API_KEY" \
  "$PROMPT"
