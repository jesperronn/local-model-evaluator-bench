# lib/versions.sh — capture tool versions for benchmarking reproducibility
# Source after config.sh and lib/common.sh
# Usage: get_version_info <adapter-name> [runtime]
#   Returns: <name>\t<version>\t<source>  (e.g., aider\t0.35.2\tpip)

get_version_info() {
  local adapter="$1" runtime="${2:-lms}"
  local version="" source=""

  # Try to get version from pip/npm/brew based on adapter type
  case "$adapter" in
    aider)
      version=$(python3 -m pip show aider 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      source="pip"
      ;;
    opencode)
      version=$(npm list -g opencode 2>/dev/null | grep opencode@ | head -1 | sed 's/.*@//' | cut -d' ' -f1)
      [ -z "$version" ] && version=$(opencode --version 2>/dev/null | head -1)
      source="npm"
      ;;
    cline)
      # cline uses pnpm, try both pnpm and binary fallback
      version=$(pnpm list -g cline 2>/dev/null | grep cline | head -1 | sed 's/.*@//' | cut -d' ' -f1)
      [ -z "$version" ] && version=$(cline --version 2>/dev/null | head -1)
      source="pnpm"
      ;;
    codex)
      version=$(python3 -m pip show cursor-codex 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      [ -z "$version" ] && version=$(codex --version 2>/dev/null | head -1)
      source="pip"
      ;;
    caveman)
      version=$(npm list -g caveman 2>/dev/null | grep caveman@ | head -1 | sed 's/.*@//' | cut -d' ' -f1)
      source="npm"
      ;;
    hermes)
      version=$(python3 -m pip show hermes-cli 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      [ -z "$version" ] && version=$(hermes --version 2>/dev/null | head -1)
      source="pip"
      ;;
    pi)
      version=$(npm list -g @earendil-works/pi-coding-agent 2>/dev/null | grep pi-coding-agent | head -1 | sed 's/.*@//' | cut -d' ' -f1)
      [ -z "$version" ] && version=$(pi --version 2>/dev/null | head -1)
      source="npm"
      ;;
    goose)
      version=$(python3 -m pip show block-goose 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      [ -z "$version" ] && version=$(goose --version 2>/dev/null | head -1)
      source="pip"
      ;;
    swe-agent)
      version=$(python3 -m pip show swe-agent 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      source="pip"
      ;;
    mini-swe-agent)
      version=$(python3 -m pip show mini-swe-agent 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      source="pip"
      ;;
    openhands)
      version=$(openhands --version 2>/dev/null | tail -1 | sed 's/.*CLI //')
      source="uv"
      ;;
    *)
      version="unknown"
      source="unknown"
      ;;
  esac

  [ -n "$version" ] || version="unknown"
  printf '%s\t%s\t%s\n' "$adapter" "$version" "$source"
}

# Get runtime version (LMS, Ollama, MLX, etc.)
get_runtime_version() {
  local runtime="$1"
  local version="" source=""

  case "$runtime" in
    lms)
      version=$(lms --version 2>/dev/null | head -1)
      source="lms"
      [ -n "$version" ] || version="unknown"
      ;;
    ollama)
      version=$(ollama --version 2>/dev/null | head -1)
      source="ollama"
      [ -n "$version" ] || version="unknown"
      ;;
    mlx)
      version=$(pip show mlx-lm 2>/dev/null | grep ^Version: | cut -d' ' -f2)
      source="mlx-lm"
      [ -n "$version" ] || version="unknown"
      ;;
    *)
      version="unknown"
      source="unknown"
      ;;
  esac

  printf '%s\t%s\t%s\n' "$runtime" "$version" "$source"
}

# Build a JSON object with all version info
# Usage: collect_versions <runtime> <comma-separated-adapters>
collect_versions() {
  local runtime="$1" adapters="$2"
  local run_id run_date run_time

  run_id=$(date +%Y%m%d-%H%M%S)
  run_date=$(date +%Y-%m-%d)
  run_time=$(date +%H:%M:%S)

  # Start JSON object
  local json="{\"run_date\":\"$run_date\",\"run_time\":\"$run_time\",\"run_id\":\"$run_id\""

  # Add runtime version
  local rt_info runtime_name runtime_ver runtime_src
  rt_info=$(get_runtime_version "$runtime")
  IFS=$'\t' read -r runtime_name runtime_ver runtime_src <<<"$rt_info"
  json+=",\"runtime\":{\"name\":\"$runtime_name\",\"version\":\"$runtime_ver\",\"source\":\"$runtime_src\"}"

  # Add agent versions
  json+=",\"agents\":{"
  local first=true
  IFS=',' read -ra adapter_list <<<"$adapters"
  for adapter in "${adapter_list[@]}"; do
    adapter="${adapter// /}"  # strip whitespace
    local ag_info agent_name agent_ver agent_src
    ag_info=$(get_version_info "$adapter" "$runtime")
    IFS=$'\t' read -r agent_name agent_ver agent_src <<<"$ag_info"

    if [ "$first" = true ]; then
      first=false
    else
      json+=","
    fi
    json+="\"$agent_name\":{\"version\":\"$agent_ver\",\"source\":\"$agent_src\"}"
  done
  json+="}"

  json+="}"
  printf '%s\n' "$json"
}
