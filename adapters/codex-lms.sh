#!/usr/bin/env bash
# Adapter: codex -> LM Studio.
# Codex talks to any OpenAI-compatible endpoint via a custom model_provider.
# We pass the provider definition inline with -c overrides so no edit to
# ~/.codex/config.toml is required. NOTE: `lmstudio` is a RESERVED built-in
# provider id in codex and cannot be overridden, so we register our own under
# `lmstudio_local`. See docs/SETUP.md for the persistent setup.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

export LMS_API_KEY  # codex reads the key from this env var (see -c env_key).

CODEX_COMMON=(
  -c model="$MODEL_ID"
  -c model_provider="lmstudio_local"
  -c model_providers.lmstudio_local.name="LM Studio"
  -c model_providers.lmstudio_local.base_url="$LMS_BASE_URL"
  -c model_providers.lmstudio_local.env_key="LMS_API_KEY"
)
if [ ! -t 0 ]; then
  exec codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "${CODEX_COMMON[@]}" "$(cat)" "$@"
else
  exec codex "${CODEX_COMMON[@]}" "$@"
fi
