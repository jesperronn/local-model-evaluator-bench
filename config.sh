# config.sh — shared settings, sourced by everything in bin/ and adapters/.
# Edit these to match your LM Studio setup.

# LM Studio's OpenAI-compatible server. Start it with: `lms server start`
export LMS_BASE_URL="${LMS_BASE_URL:-http://localhost:1234/v1}"
# LM Studio ignores the key, but the clients require *some* value.
export LMS_API_KEY="${LMS_API_KEY:-lm-studio}"

# Model used by `bin/smoke` to verify every tool can reach LM Studio. Pick a
# small, fast one — the smoke case is trivial, so capability doesn't matter.
export SMOKE_MODEL="${SMOKE_MODEL:-google/gemma-4-e4b}"
# How long the smoke model stays loaded after its last use (seconds), so the
# smoke test doesn't leave memory occupied. Set empty to keep it loaded.
export SMOKE_TTL="${SMOKE_TTL:-600}"

# Which CLI adapters to exercise by default (one file per name in adapters/).
# Override per-run with:  bin/bench --adapters aider,opencode
DEFAULT_ADAPTERS="${DEFAULT_ADAPTERS:-aider,opencode,codex,caveman,hermes}"

# Repo root, resolved regardless of where you invoke from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
export CASES_DIR="$REPO_ROOT/cases"
export RESULTS_DIR="$REPO_ROOT/results"
export ADAPTERS_DIR="$REPO_ROOT/adapters"
export MODELS_FILE="$REPO_ROOT/models.txt"
