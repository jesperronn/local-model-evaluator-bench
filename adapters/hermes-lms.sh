#!/usr/bin/env bash
# Adapter: hermes -> LM Studio.
# hermes runs non-interactively with -z (prompt) and -m/--provider. It ships an
# `lmstudio` provider already pointed at LM Studio (see ~/.hermes/config.yaml:
# provider: lmstudio, base_url: http://127.0.0.1:1234/v1). We select it by name.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
PROMPT="$(cat)"

# -t file,terminal enables the file-edit + shell toolsets (default is none, so
# without this hermes just chats and never touches the filesystem).
#
# NO-YOLO SETUP (recommended for testing hermes): instead of --yolo (which
# bypasses all approvals), we rely on ~/.hermes/config.yaml `approvals.mode:
# smart` — an LLM "guardian" auto-approves safe ops, denies dangerous ones, and
# escalates uncertain ones (60s timeout -> deny). The guardian uses the same
# local LM Studio model (approval.provider: auto). For edits to reach the host
# sandbox, that config also needs `terminal.backend: local` (tools run on the
# host, gated by the smart guardian). `bin/doctor` verifies this is set up.
# Note: hermes refuses writes under /private/var (macOS mktemp); bench sandboxes
# live under results/, which is fine.
exec hermes \
  --provider lmstudio \
  -m "$MODEL_ID" \
  -t file,terminal \
  -z "$PROMPT" \
  "$@"
