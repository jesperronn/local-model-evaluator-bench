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
# KNOWN LIMITATION (why hermes is not in DEFAULT_ADAPTERS): hermes executes its
# tools in an isolated CONTAINER workspace (~/.hermes/config.yaml:
# docker_image=..., docker_mount_cwd_to_workspace: false), so file edits land in
# the container, never in our host sandbox — every case scores 0 regardless of
# model. To benchmark hermes like the other CLIs, enable cwd mounting / a local
# execution backend in ~/.hermes/config.yaml (a dotfiles concern; hermes guards
# that file from agent edits), then add `hermes` back to DEFAULT_ADAPTERS.
# Also note: hermes refuses writes under /private/var (macOS mktemp), so any
# sandbox must live on a normal path — bench puts them under results/, fine.
exec hermes \
  --provider lmstudio \
  -m "$MODEL_ID" \
  -t file,terminal \
  --yolo \
  -z "$PROMPT"
