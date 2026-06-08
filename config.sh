# config.sh — shared settings, sourced by everything in bin/ and adapters/.
# Edit these to match your LM Studio setup.

# LM Studio's OpenAI-compatible server. Start it with: `lms server start`
export LMS_BASE_URL="${LMS_BASE_URL:-http://localhost:1234/v1}"
# LM Studio ignores the key, but the clients require *some* value.
export LMS_API_KEY="${LMS_API_KEY:-lm-studio}"

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
# CONTEXT: token budget per request; 32768 covers full-file edits + tool call
#   history. Safe to push higher on 128 GB — the KV cache cost is low.
# PARALLEL: slots for simultaneous predictions. bench is sequential so 1 gives
#   best single-request throughput. Raise to 2-4 if you run other tools
#   against the same model concurrently while bench is running.
export BENCH_TTL_MINUTES="${BENCH_TTL_MINUTES:-10}"
export BENCH_CONTEXT="${BENCH_CONTEXT:-32768}"
export BENCH_PARALLEL="${BENCH_PARALLEL:-1}"

# Which CLI adapters to exercise by default (one file per name in adapters/).
# Override per-run with:  bin/bench --adapters aider,opencode
# `hermes` requires a one-time config (terminal.backend: local + approvals.mode:
# smart in ~/.hermes/config.yaml) so its tools edit the host sandbox under an
# LLM approval guardian instead of --yolo. `bin/doctor` verifies it. If not set
# up, drop hermes from this list.
DEFAULT_ADAPTERS="${DEFAULT_ADAPTERS:-aider,opencode,codex,caveman,hermes}"

# Repo root, resolved regardless of where you invoke from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
export CASES_DIR="$REPO_ROOT/cases"
export RESULTS_DIR="$REPO_ROOT/results"
export ADAPTERS_DIR="$REPO_ROOT/adapters"
export MODELS_FILE="$REPO_ROOT/models.txt"
