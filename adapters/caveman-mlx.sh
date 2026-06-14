#!/usr/bin/env bash
# Adapter: caveman -> mlx_lm.server.
# KNOWN LIMITATION: caveman only resolves models from its built-in model list.
# Custom model IDs (mlx-community/*, /path/to/model) cannot be registered as
# a new provider name in models.json — caveman only accepts overrides for
# models it already knows. This adapter exits cleanly so the bench records 0%
# rather than logging connection errors.
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
if [ ! -t 0 ]; then cat > /dev/null; fi  # drain stdin when piped

echo "caveman-mlx: skipped — caveman built-in model list required; MLX model IDs not supported" >&2
exit 1
