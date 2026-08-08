#!/usr/bin/env bash
# Adapter: qwen (Qwen Code CLI) -> oMLX.
# Qwen Code's "openai" auth type is surfaced without any settings.json —
# OPENAI_API_KEY/OPENAI_BASE_URL/OPENAI_MODEL alone select it. No provider
# catalog to keep in sync, unlike pi/opencode.
# Three env vars are required to stop qwen from calling home to Alibaba on
# every run, regardless of the configured model provider. Found by proxying
# all traffic through a local CONNECT-logging stub and inspecting targets:
#   - QWEN_USAGE_STATISTICS_ENABLED=false: disables qwen-logger.ts, which
#     otherwise ships usage/error telemetry to Alibaba Cloud RUM
#     (*.rum.aliyuncs.com) every ~60s (privacy.usageStatisticsEnabled,
#     default on). This is the one that matters most — it's an ongoing
#     background pipe, not a one-shot check.
#   - QWEN_CODE_DISABLE_PRECONNECT=1: disables apiPreconnect.ts, which
#     otherwise HEAD-requests a hardcoded DEFAULT_BASE_URLS table (including
#     dashscope.aliyuncs.com) at startup as a latency optimization, even when
#     a custom baseUrl is configured.
#   - QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true: skips the standalone-update
#     check (general.enableAutoUpdate, default on), which hits Alibaba OSS
#     (qwen-code-assets.oss-cn-hangzhou.aliyuncs.com).
# Verified clean after all three: zero non-oMLX CONNECT targets over 3 runs.
# Start the server first: bin/omlx start
# Contract: CWD is the sandbox. Prompt on stdin. $MODEL_ID set.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config.sh"
MODEL_ID="${MODEL_ID:-$PREFERRED_MODEL_ID}"

command -v qwen >/dev/null 2>&1 || {
  echo "qwen not found; install: npm install -g @qwen-code/qwen-code" >&2
  exit 1
}

export OPENAI_API_KEY="$OMLX_API_KEY"
export OPENAI_BASE_URL="$OMLX_BASE_URL"
export OPENAI_MODEL="$MODEL_ID"
export QWEN_CODE_SUPPRESS_YOLO_WARNING=1
export QWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true
export QWEN_CODE_DISABLE_PRECONNECT=1
export QWEN_USAGE_STATISTICS_ENABLED=false

QWEN_ARGS=(--model "$MODEL_ID" --approval-mode yolo)

if [ ! -t 0 ]; then
  exec qwen "${QWEN_ARGS[@]}" -p "$(cat)"
else
  exec qwen "${QWEN_ARGS[@]}" "$@"
fi
