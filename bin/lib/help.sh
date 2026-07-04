# lib/help.sh — fancy help output with color, alignment, and structure.
# Source after lib/common.sh (needs color variables like C_BLD, C_YEL, etc).
# Usage:
#   help_header "bench" "run the matrix of (adapter x model x case)"
#   help_section "USAGE"
#   help_line "  bench [OPTIONS]" ""
#   help_section "OPTIONS"
#   help_flag "--agent,-a" "a,b" "CLI adapters to run (default: aider,cline)"
#   help_flag "--timeout" "N" "per-trial HARD ceiling, seconds (default: 300)"
#   help_section "EXAMPLES"
#   help_line "  run default config:" ""
#   help_line "  \$ bench" ""

# Print a formatted help header with tool name and brief description.
help_header() {
  local name="$1" desc="$2"
  printf '%s\n' "${C_BLD}${name}${C_RST} — ${C_DIM}${desc}${C_RST}"
}

# Print a section heading (USAGE, OPTIONS, EXAMPLES, etc).
help_section() {
  local section="$1"
  printf '\n%s\n' "${C_YEL}${section}${C_RST}"
}

# Print a generic help line (no flag coloring).
help_line() {
  local line="$1"
  printf '%s\n' "$line"
}

# Print a flag with argument placeholder and description.
# Aligns descriptions at column 28 for readability.
help_flag() {
  local flag="$1" arg="$2" desc="$3"
  local fmt="%s%-26s  %s\n"
  if [ -z "$arg" ]; then
    # Flag without argument
    printf "$fmt" "${C_YEL}" "${flag}${C_RST}" "$desc"
  else
    # Flag with argument (show in magenta as placeholder)
    printf "$fmt" "${C_YEL}" "${flag}${C_RST} ${C_DIM}<${arg}>${C_RST}" "$desc"
  fi
}

# Print multiple flags under a group heading (e.g. "Tool flags:" or "Model flags:").
# Useful for organizing related options.
help_flag_group() {
  local group_name="$1"
  shift
  local flags=("$@")

  printf '\n%s\n' "${C_BLD}${group_name}${C_RST}"
  for flag_spec in "${flags[@]}"; do
    # Parse "flag|arg|description" format
    local IFS='|'
    read -r flag arg desc <<< "$flag_spec"
    help_flag "$flag" "$arg" "$desc"
  done
}

# Print an environment variable with description.
help_env() {
  local var="$1" default="$2" desc="$3"
  local fmt="%s%-26s  %s\n"
  if [ -z "$default" ]; then
    printf "$fmt" "${C_BLU}" "${var}${C_RST}" "$desc"
  else
    printf "$fmt" "${C_BLU}" "${var}${C_RST}" "$desc (default: $default)"
  fi
}

# Print a sub-command with optional short description.
help_command() {
  local cmd="$1" desc="${2:-}"
  printf '%s%s%s' "${C_GRN}" "$cmd" "${C_RST}"
  if [ -n "$desc" ]; then
    printf '  %s\n' "$desc"
  else
    printf '\n'
  fi
}

# Convenience: print the canonical help footer with next steps.
help_footer() {
  printf '\n%s\n' "${C_DIM}For more info, run: \$ <command> --help${C_RST}"
}
