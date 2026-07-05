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
# See docs/ADAPTER-SETUP.md and docs/AGENT-SELECTION.md for full compatibility matrix.
DEFAULT_ADAPTERS="${DEFAULT_ADAPTERS:-aider,cline,codex,caveman,hermes,interpreter,opencode,openhands,pi,goose,copilot,nanocoder,cn}"

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
export MODELS_FILE="$REPO_ROOT/models.txt"
