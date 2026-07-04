#!/usr/bin/env bash
# bin/lib/model-profiles.sh — parse models-recommended.conf and resolve aliases
#
# Usage:
#   profiles_list              # list all available profiles
#   profile_exists <name>      # test if profile exists
#   profile_aliases <name>     # get space-separated aliases for profile
#   profile_primary <name>     # get primary (recommended) alias
#   alias_ids <alias> <rt>    # get model id for alias + runtime (rt=lms|ollama|mlx)
#   profile_description <name> # get tier description

set -uo pipefail

# When sourced, use the parent script's HERE; when run directly, calculate it
if [ -z "${HERE:-}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
MODELS_RECOMMENDED="${HERE}/models-recommended.conf"
MODELS_ALIASES="${HERE}/models-aliases.conf"

# ── List all profile names ────────────────────────────────────────────────────
profiles_list() {
  command grep -v '^#' "$MODELS_RECOMMENDED" | command grep -v '^[[:space:]]*$' | awk -F'|' '{print $1}' | xargs
}

# ── Test if profile exists ────────────────────────────────────────────────────
profile_exists() {
  local name="$1"
  command grep -q "^$name[[:space:]]" "$MODELS_RECOMMENDED"
}

# ── Get description for profile ──────────────────────────────────────────────
profile_description() {
  local name="$1"
  command grep "^$name[[:space:]]" "$MODELS_RECOMMENDED" | awk -F'|' '{print $4}' | xargs
}

# ── Get aliases for a profile (space-separated) ──────────────────────────────
profile_aliases() {
  local name="$1"
  command grep "^$name[[:space:]]" "$MODELS_RECOMMENDED" | awk -F'|' '{print $5}' | xargs | tr ',' ' '
}

# ── Get primary (recommended) alias for profile ──────────────────────────────
profile_primary() {
  local name="$1"
  command grep "^$name[[:space:]]" "$MODELS_RECOMMENDED" | awk -F'|' '{print $6}' | xargs
}

# ── Get model id for alias + runtime ──────────────────────────────────────────
# Returns "-" if model is not available for that runtime
alias_ids() {
  local alias="$1" rt="${2:-lms}"
  # rt index: lms=2, mlx=3, ollama=4
  local col
  case "$rt" in
    lms)    col=2;;
    mlx)    col=3;;
    ollama) col=4;;
    *)      return 1;;
  esac
  command grep "^$alias" "$MODELS_ALIASES" | awk -F'\t' "{print \$$col}" | xargs
}

# ── Get all aliases available (across all profiles) ───────────────────────────
available_aliases() {
  awk -F'|' 'NF >= 5 && !/^#/ && NF > 0 {print $5}' "$MODELS_RECOMMENDED" | \
    tr ',' '\n' | xargs -n1 | sort -u
}

# ── Validate: check if all aliases in a profile exist in models-aliases.conf ──
validate_profile() {
  local name="$1"
  local aliases; aliases="$(profile_aliases "$name")"
  local all_ok=1
  for alias in $aliases; do
    if ! command grep -q "^$alias" "$MODELS_ALIASES"; then
      printf 'error: alias "%s" in profile "%s" not found in models-aliases.conf\n' "$alias" "$name" >&2
      all_ok=0
    fi
  done
  return $((1 - all_ok))
}
