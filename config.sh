# config.sh — shared settings, sourced by everything in bin/ and adapters/.
# Edit these to match your LM Studio setup.

# LM Studio's OpenAI-compatible server. Start it with: `lms server start`
export LMS_BASE_URL="${LMS_BASE_URL:-http://127.0.0.1:1234/v1}"
# LM Studio ignores the key, but the clients require *some* value.
export LMS_API_KEY="${LMS_API_KEY:-lm-studio}"

# Ollama base URL used by adapters. Override to route through bin/tool-call-proxy
# when testing models (e.g. qwen2.5-coder) that emit JSON text instead of
# structured tool_calls:
#   OLLAMA_BASE_URL=http://127.0.0.1:11435/v1 bin/bench --runtime ollama ...
# Start the proxy first: bin/tool-call-proxy &
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://127.0.0.1:11434/v1}"

# oMLX (https://omlx.app) — multi-model MLX server for Apple Silicon. Unlike
# mlx_lm.server (one model per process on :8080), oMLX serves every model under
# its model dir and swaps them LRU, so it behaves like LM Studio/Ollama: models
# are addressed by directory basename and need no manual (re)start per model.
# Port 8000 is oMLX's own configured default (~/.omlx/settings.json).
# Start it with: bin/omlx start
export OMLX_BASE_URL="${OMLX_BASE_URL:-http://127.0.0.1:8000/v1}"
# oMLX runs unauthenticated by default; clients still require *some* value.
export OMLX_API_KEY="${OMLX_API_KEY:-omlx}"
# Directory oMLX discovers models from — used by bin/setup and bin/doctor to
# report what is installed without going through the HTTP API.
export OMLX_MODELS_DIR="${OMLX_MODELS_DIR:-$HOME/.omlx/models}"
# Whether bin/bench force-unloads the model from oMLX after each (adapter x
# model) sweep. Default 0: oMLX is a multi-model LRU server (bin/omlx status
# shows model_memory_used vs model_memory_max) that evicts on its own under
# memory pressure — leaving models resident lets you run other models
# concurrently against the same server. Set to 1 to force an unload after
# every model (guarantees each model's timings are measured cold, at the
# cost of evicting anything else you had resident).
export BENCH_OMLX_UNLOAD="${BENCH_OMLX_UNLOAD:-0}"

# mlx_lm.server — one model per process, restart to switch (unlike oMLX/MTPLX,
# which are multi-model). Default port is mlx_lm.server's own default.
export MLX_BASE_URL="${MLX_BASE_URL:-http://127.0.0.1:8080/v1}"

# LiteLLM proxy — unified endpoint fronting all five local runtimes (lms, ollama, mlx, omlx, mtplx).
# NEW PROXY-FIRST APPROACH: When LITELLM_BASE_URL is set, adapters prefer it and fall back to
# direct runtime endpoints only if proxy is unavailable. Use bin/litellm-proxy to run the
# Docker-backed service; models are addressed as lms/<id>, ollama/<id>, mlx/<id>, omlx/<id>, mtplx/<id>.
export LITELLM_PROXY_MODE="${LITELLM_PROXY_MODE:-1}"  # 1 = proxy available; set to 0 to disable
export LITELLM_PORT="${LITELLM_PORT:-4444}"
export LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://127.0.0.1:${LITELLM_PORT}/v1}"
# Unset by default: litellm does not require a key for any endpoint (including
# the store_model_in_db admin routes like /model/new) unless one is set. This
# proxy binds only to 127.0.0.1 on a single-user machine, so no key is needed.
# Set LITELLM_MASTER_KEY yourself if this ever needs to be reachable beyond
# localhost or shared with another user.
export LITELLM_MASTER_KEY="${LITELLM_MASTER_KEY:-}"
# Postgres backing store for store_model_in_db (litellm requires Postgres, no
# sqlite support). bin/litellm-proxy runs this in a local Docker container
# named litellm-postgres, so no system Postgres install is needed.
export LITELLM_PG_CONTAINER="${LITELLM_PG_CONTAINER:-litellm-postgres}"
export LITELLM_PG_PORT="${LITELLM_PG_PORT:-5443}"
export DATABASE_URL="${DATABASE_URL:-postgresql://litellm:litellm@127.0.0.1:${LITELLM_PG_PORT}/litellm}"

# MTPLX (https://github.com/youssofal/MTPLX) — local multi-model server, also
# OpenAI-compatible. Its default port (8000) collides with oMLX's, so it's
# moved to 8001 here; start the API-only server with:
#   mtplx quickstart --port 8001 --model <model>

export MTPLX_PORT="${MTPLX_PORT:-8001}"
export MTPLX_BASE_URL="${MTPLX_BASE_URL:-http://127.0.0.1:${MTPLX_PORT}/v1}"
export MTPLX_API_KEY="${MTPLX_API_KEY:-mtplx}"

# Default model used by adapters when MODEL_ID is not set externally.
# Override per-invocation with:  MODEL_ID=other/model adapter/copilot-lms.sh
# Standard model for local evaluations: Ornith-1.5-35B-A3B-MLX-4bit via omlx
export PREFERRED_MODEL_ID="${PREFERRED_MODEL_ID:-Ornith-1.5-35B-A3B-MLX-4bit}"

# Model used by `bin/smoke` to verify every tool can reach LM Studio. Pick a
# small, fast one — the smoke case is trivial, so capability doesn't matter.
export SMOKE_MODEL="${SMOKE_MODEL:-google/gemma-4-e4b}"
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
#   On 32 GB: use 65536 for qwen3.5-9b (tiny KV cache), reduce to 32768 for larger models.
# PARALLEL: slots for simultaneous predictions. Each agent adds ~4 GB KV cache at 65K context.
#   Auto-calculated per machine RAM: ≤32GB→2, 64GB→3, 128GB+→4. Override with
#   BENCH_PARALLEL=N if needed. See lib/common.sh:_get_bench_parallel_for_ram().
export BENCH_TTL_MINUTES="${BENCH_TTL_MINUTES:-10}"
export BENCH_CONTEXT="${BENCH_CONTEXT:-65536}"

# Guardrails configuration — safety filters for model outputs. Disabled by default.
export GUARDRAILS_ENABLED="${GUARDRAILS_ENABLED:-false}"         # false|true
export GUARDRAILS_ENGINE="${GUARDRAILS_ENGINE:-}"                # runtime engine (e.g., guardrails-ai)
export GUARDRAILS_ENTITIES="${GUARDRAILS_ENTITIES:-}"            # comma-separated entity types to filter
export GUARDRAILS_MODE="${GUARDRAILS_MODE:-moderate}"            # filter strictness: lenient|moderate|strict
export GUARDRAILS_SCORE_THRESHOLD="${GUARDRAILS_SCORE_THRESHOLD:-0.85}"  # min confidence to block (0.0–1.0)

# Source common.sh to access hardware detection, but only if we haven't already
# (avoids double-sourcing in scripts that source config.sh multiple times).
if [ -z "${_COMMON_SH_LOADED:-}" ]; then
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
  _COMMON_SH_LOADED=1
fi

# Calculate BENCH_PARALLEL based on machine RAM if not already set by user.
if [ -z "${BENCH_PARALLEL_EXPLICIT:-}" ]; then
  _AUTO_PARALLEL=$(_get_bench_parallel_for_ram)
  export BENCH_PARALLEL="${BENCH_PARALLEL:-$_AUTO_PARALLEL}"
else
  export BENCH_PARALLEL="${BENCH_PARALLEL}"
fi

# Which CLI adapters to exercise by default (one file per name in adapters/).
# Override per-run with:  bin/bench --adapters aider,opencode
# `hermes` requires a one-time config (terminal.backend: local + approvals.mode:
# smart in ~/.hermes/config.yaml) so its tools edit the host sandbox under an
# LLM approval guardian instead of --yolo. `bin/doctor` verifies it. If not set
# up, drop hermes from this list.
# All adapters available for testing. Guidance on which to prefer:
#   ✨ Recommended: openhands (fast+accurate), cline (100% accurate), aider (reliable)
#   ⚠️  Caution: goose (slow), pi (very slow), opencode (very slow)
#   ❌ Incompatible: copilot (cloud-only, expects Anthropic API not local models), claude (SDK incompatibility with local servers)
# For small model evaluation (3.8B-9B): use pi only (verified via fair-comparison testing 2026-07-05)
# See docs/ADAPTER-SETUP.md and docs/AGENT-SELECTION.md for full compatibility matrix.
DEFAULT_ADAPTERS="${DEFAULT_ADAPTERS:-pi}"

# Adapter configuration defaults — applied globally by `bin/suggest-tuning | llmrun agents config apply`.
# These are fallback values; model-specific overrides in docs/models/*.md take precedence.
export ADAPTER_DEFAULT_TEMPERATURE="${ADAPTER_DEFAULT_TEMPERATURE:-0.7}"    # coding: deterministic but not stiff
export ADAPTER_DEFAULT_MAX_TOKENS="${ADAPTER_DEFAULT_MAX_TOKENS:-8192}"     # typical response + edits
export ADAPTER_DEFAULT_TOOL_CHOICE="${ADAPTER_DEFAULT_TOOL_CHOICE:-auto}"   # use tools when needed
# Anti-loop penalties for reasoning models. Empty by default (no override) so
# baseline runs are unaffected; set to 0.1–0.3 only when enabling reasoning, to
# discourage the attention-reinforcement trap (repeated "Wait…"/"Actually…").
# See docs/troubleshooting-qwen-reasoning-loops.md. Currently only wired into
# the cn adapter (Continue's defaultCompletionOptions forwards them to the API);
# pi has no CLI sampling flags, cline has none — see that doc's plumbing note.
export ADAPTER_DEFAULT_PRESENCE_PENALTY="${ADAPTER_DEFAULT_PRESENCE_PENALTY:-}"   # 0.1–0.3 if reasoning on
export ADAPTER_DEFAULT_FREQUENCY_PENALTY="${ADAPTER_DEFAULT_FREQUENCY_PENALTY:-}" # 0.1–0.3 if reasoning on
# Reasoning toggle for adapters that support it (cn). "off" (default) strips/avoids
# <think>; "on" enables chain-of-thought. Override per-run: ADAPTER_REASONING=on
export ADAPTER_REASONING="${ADAPTER_REASONING:-off}"                          # off|on

# Repo root, resolved regardless of where you invoke from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
export CASES_DIR="$REPO_ROOT/cases"
export RESULTS_DIR="$REPO_ROOT/results"
export ADAPTERS_DIR="$REPO_ROOT/adapters"
