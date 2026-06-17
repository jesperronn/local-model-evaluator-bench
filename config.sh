# config.sh — shared settings, sourced by everything in bin/ and adapters/.
# Edit these to match your LM Studio setup.

# LM Studio's OpenAI-compatible server. Start it with: `lms server start`
export LMS_BASE_URL="${LMS_BASE_URL:-http://localhost:1234/v1}"
# LM Studio ignores the key, but the clients require *some* value.
export LMS_API_KEY="${LMS_API_KEY:-lm-studio}"

# Ollama base URL used by adapters. Override to route through bin/tool-call-proxy
# when testing models (e.g. qwen2.5-coder) that emit JSON text instead of
# structured tool_calls:
#   OLLAMA_BASE_URL=http://localhost:11435/v1 bin/bench --runtime ollama ...
# Start the proxy first: bin/tool-call-proxy &
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434/v1}"

# Default model used by adapters when MODEL_ID is not set externally.
# Override per-invocation with:  MODEL_ID=other/model adapter/copilot-lms.sh
export PREFERRED_MODEL_ID="${PREFERRED_MODEL_ID:-qwen/qwen3.6-35b-a3b}"

# Model used by `bin/smoke` to verify every tool can reach LM Studio. Pick a
# small, fast one — the smoke case is trivial, so capability doesn't matter.
export SMOKE_MODEL="${SMOKE_MODEL:-google/gemma-4-e2b}"
# Context window for the smoke model. Must be ≥64000 so all adapters (including
# Hermes, which enforces a 64K floor) can reach it.
export SMOKE_CTX="${SMOKE_CTX:-64000}"
# How long the smoke model stays loaded after its last use (seconds), so the
# smoke test doesn't leave memory occupied. Set empty to keep it loaded.
export SMOKE_TTL="${SMOKE_TTL:-600}"

# bench load parameters — applied whenever bin/bench loads a model.
# TTL: auto-unload after this many minutes of inactivity (bench loads are
#   short-lived; 10 min distinguishes them from manually loaded models).
# CONTEXT: token budget per request. Must be ≥64000 — Hermes enforces a hard 64K
#   floor and aborts on startup (error in ~3s) for any smaller model, which is
#   what silently zeroed every hermes trial. 65536 also covers full-file edits +
#   tool-call history for the other adapters. Safe on 128 GB — KV cache cost is low.
# PARALLEL: slots for simultaneous predictions. Set to match the real
#   multi-agent concurrency you care about (orchestrator + 2-3 agents = 3-4).
#   Default 3 mirrors the target workload; lower to 1 for max single-request
#   throughput, raise to 4 for a heavier orchestration scenario.
export BENCH_TTL_MINUTES="${BENCH_TTL_MINUTES:-10}"
export BENCH_CONTEXT="${BENCH_CONTEXT:-65536}"
export BENCH_PARALLEL="${BENCH_PARALLEL:-3}"

# Which CLI adapters to exercise by default (one file per name in adapters/).
# Override per-run with:  bin/bench --adapters aider,opencode
# `hermes` requires a one-time config (terminal.backend: local + approvals.mode:
# smart in ~/.hermes/config.yaml) so its tools edit the host sandbox under an
# LLM approval guardian instead of --yolo. `bin/doctor` verifies it. If not set
# up, drop hermes from this list.
DEFAULT_ADAPTERS="${DEFAULT_ADAPTERS:-aider,opencode,codex,caveman,hermes,cline,interpreter,pi}"

# Repo root, resolved regardless of where you invoke from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
export CASES_DIR="$REPO_ROOT/cases"
export RESULTS_DIR="$REPO_ROOT/results"
export ADAPTERS_DIR="$REPO_ROOT/adapters"
export MODELS_FILE="$REPO_ROOT/models.txt"
