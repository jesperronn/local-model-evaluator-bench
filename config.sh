# config.sh — shared settings, sourced by everything in bin/ and adapters/.
# Edit these to match your LM Studio setup.

# LM Studio's OpenAI-compatible server. Start it with: `lms server start`
export LMS_BASE_URL="${LMS_BASE_URL:-http://localhost:1234/v1}"
# LM Studio ignores the key, but the clients require *some* value.
export LMS_API_KEY="${LMS_API_KEY:-lm-studio}"

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
