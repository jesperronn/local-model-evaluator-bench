#!/usr/bin/env bash
# Adapter: codex -> mlx_lm.server.
# KNOWN LIMITATION: codex wire_api is an enum that only accepts "responses";
# "chat-completions" is not a valid value. The --oss path uses chat-completions
# but only with --local-provider ollama (11434) or lmstudio (1234) — neither
# maps to mlx_lm.server's port 8080. This adapter is therefore a stub that
# exits cleanly so the bench records 0% rather than looping with connection errors.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
cat > /dev/null  # drain stdin

echo "codex-mlx: skipped — codex wire_api enum blocks chat-completions on custom providers" >&2
exit 1
