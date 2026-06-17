#!/usr/bin/env bash
# Adapter: codex -> Ollama.
# Codex has a built-in `--oss --local-provider ollama` path that uses
# /v1/chat/completions instead of /v1/responses (which Ollama doesn't support).
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail

CODEX_COMMON=(
  --oss
  --local-provider ollama
  -m "$MODEL_ID"
)
if [ ! -t 0 ]; then
  exec codex exec --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox "${CODEX_COMMON[@]}" "$(cat)" "$@"
else
  exec codex "${CODEX_COMMON[@]}" "$@"
fi
