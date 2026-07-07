# lib/delegation-check.sh — diagnostic CHECK lines about subagent delegation.
#
# SOURCE this from a case grader AFTER the authoritative RESULT is emitted. An
# orchestrator adapter (e.g. adapters/*-orch-*.sh) writes a `.delegation` marker
# into the sandbox after its run:
#     subagents=<N>          # count of subagent/task spawns detected in traces
# This reads it and emits diagnostic CHECK lines that bin/bench folds into
# checks.csv. Baseline single-agent adapters leave no marker, so nothing is
# emitted — the absence itself records "did not delegate" for that combo.
#
# CHECK lines are diagnostic only; the case's RESULT stays authoritative for
# scoring, so the same case is comparable across baseline and orchestrator
# adapters.

# Return cleanly whether sourced or executed.
if [ ! -f .delegation ]; then
  return 0 2>/dev/null || exit 0
fi

_dc_subagents=0
while IFS='=' read -r _dc_k _dc_v; do
  case "$_dc_k" in
    subagents) _dc_subagents="$_dc_v" ;;
  esac
done < .delegation

if [ "${_dc_subagents:-0}" -ge 1 ]; then
  echo "CHECK pass delegated to subagent (${_dc_subagents} spawned)"
else
  echo "CHECK fail delegated to subagent (0 spawned)"
fi
