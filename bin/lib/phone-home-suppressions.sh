# lib/phone-home-suppressions.sh — known env-var suppressions for CLI tools
# that phone home independently of model routing (telemetry, update checks,
# "preconnect" latency pings). Keyed by tool name (the adapter filename's
# prefix before -lms/-mlx/-ollama/-omlx), not by adapter, since the same CLI
# binary behaves the same way regardless of which runtime it talks to.
#
# This table is the actual deliverable per docs/HANDOFF-phone-home-audit.md:
# `bin/phone-home-audit --fix` applies these to the relevant adapter script
# instead of a human re-discovering them per adapter. Detect logic only tells
# you where to look next — add a row here once you've confirmed (via
# bin/phone-home-audit's proxy trace, or manual lsof/proxy digging) which env
# var actually silences a given destination.
#
# Format, one entry per line (tab-separated):
#   tool<TAB>ENV_VAR=value<TAB>host_fragment<TAB>description
#
# host_fragment is informational (used in reports); it is NOT required to
# match for --fix to apply the suppression, since some destinations are IP-only
# and never resolved to a hostname.
PHONE_HOME_SUPPRESSIONS=(
$'qwen\tQWEN_USAGE_STATISTICS_ENABLED=false\trum.aliyuncs.com\tusage/error telemetry (Alibaba Cloud RUM), recurring ~60s — privacy.usageStatisticsEnabled, default on'
$'qwen\tQWEN_CODE_DISABLE_PRECONNECT=1\tdashscope.aliyuncs.com\tstartup latency "preconnect" HEAD request against a hardcoded DEFAULT_BASE_URLS table, fires even with a custom baseUrl configured'
$'qwen\tQWEN_CODE_SKIP_UPDATE_CHECK_ONCE=true\tqwen-code-assets.oss-cn-hangzhou.aliyuncs.com\tstandalone-update check — general.enableAutoUpdate, default on'
)

# Print "ENV_VAR=value\thost_fragment\tdescription" lines for a given tool name.
phone_home_suppressions_for() {
  local tool="$1" row
  for row in "${PHONE_HOME_SUPPRESSIONS[@]}"; do
    if [ "${row%%$'\t'*}" = "$tool" ]; then
      printf '%s\n' "${row#*$'\t'}"
    fi
  done
}

# True (exit 0) if any suppression rows exist for this tool.
phone_home_has_suppressions() {
  [ -n "$(phone_home_suppressions_for "$1")" ]
}
