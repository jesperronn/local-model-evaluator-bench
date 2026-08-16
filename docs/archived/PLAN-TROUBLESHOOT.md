# bin/troubleshoot — implementation complete

Status: Ready for testing & integration
Raised: 2026-06-28 (side chat) — sparked by ad-hoc commands used to diagnose copilot/caveman failures
Implemented: 2026-06-28

## Problem

Troubleshooting a failing (adapter, model, case) combo currently requires improvised one-off commands:

```
find results/RUN/sandbox/ADAPTER/MODEL/CASE -name .bench.log | xargs cat | tail -50
head -30 adapters/ADAPTER-RUNTIME.sh         # read "Known incompatibilities"
grep ADAPTER compat.json
bin/smoke --runtime lms --model X --adapter Y --verbose
```

No single entrypoint. Each session reinvents the path.

## Existing landscape (borders to respect)

| Tool | Scope | Output |
|---|---|---|
| `bin/doctor` | env (servers, CLIs, models present) | stdout health check |
| `bin/investigate` | pi/caveman tool-call signature triage | markdown report + stdout |
| `bin/report` | aggregate leaderboards | tables |
| `bin/smoke` | quick 3-case sanity run | bench results |
| `compat.json` | tracked adapter+model+runtime incompatibilities | json |

## Design decisions (CONFIRMED)

1. **New command `bin/troubleshoot`** — doctor/investigate/report all have orthogonal scopes; folding troubleshoot into any of them blurs the border. ✅
2. **Peer of `investigate`, not parent** — investigate stays signature-focused (pi/caveman); troubleshoot is generic. ✅
3. **Input**: `bin/troubleshoot <adapter> <model> [case] [--run RUN_ID]` (default: latest run with combo).
4. **Output**: stdout by default, `--report` for markdown in `results/troubleshoots/<stamp>.md`.
5. **compat.json**: read-only; `--update-docs` flag appends with `status: open`, `first_seen: today`. No silent writes. ✅ (renamed from `--record` for clarity; signals future AI summary capability)
6. **Trigger**: manual by default. ✅ **BUT: smoketest must emit troubleshoot commands as copy-paste suggestions when a combo fails** (critical UX: next-step clarity without context-switching).
7. **Version tracking**: INCLUDE in v1 (not defer). Surface tool-version mismatches from compat.json to detect stale incompatibilities when adapters/runtimes update. ✅

## Concrete behavior

For input `(adapter, model, case, run?)`:

1. **Resolve .bench.log path**: `results/RUN/sandbox/ADAPTER/SANITIZED_MODEL/CASE/.bench.log`
2. **Last 50 lines**: print with highlight `error|MISS|Failed|FAIL`
3. **Adapter header**: extract "Known model incompatibilities" block from `adapters/ADAPTER-RUNTIME.sh`
4. **Compat lookup**: print matching `compat.json` entries
5. **Version mismatch check**: for each compat entry, compare tool version in compat vs. installed; flag stale entries
6. **Regression check**: find last successful run for this combo; show run_id + delta
7. **Suggested next action**:
   - Matching compat entry, `status: open` → "documented, see X"
   - Version mismatch → "adapter/runtime updated; rerun `bin/smoke` for re-triage"
   - Pattern matches known signature → "run `bin/investigate`"
   - Else → "rerun with `--verbose`; if reproducible, `bin/troubleshoot --update-docs`"

## Smoketest integration

When `bin/smoke` encounters a failure in a combo:
- Print failure summary to stderr
- Emit a **suggested troubleshoot command** as a code block (copy-paste ready):
  ```bash
  bin/troubleshoot <adapter> <model> <case> --run <LATEST_RUN_ID>
  ```
- This bridges the gap: user sees failure, immediately knows next diagnostic step without context-switch.

## Resolved decisions (round 1)

1. ✅ **Border w/ investigate**: peer (confirmed).
2. ✅ **compat.json writes**: read-only + `--update-docs` flag (no silent writes).
3. ✅ **Trigger**: manual by default, BUT smoketest emits troubleshoot commands as copy-paste suggestions on failure.
4. ✅ **Regression check scoping**: O(N) scan acceptable; plan dedup for later (v2).
5. ✅ **Version tracking**: MUST include in v1. Surface tool-version mismatches from compat.json (e.g., `compat` says cline 3.0.31, installed is 3.1.0 → flag as stale). Enables re-triage when adapters/runtimes update.

## Command boundaries and user journeys

| User scenario | Primary flow | Tool sequence |
|---|---|---|
| "Is my setup working?" | Health check | `bin/doctor` (env OK?) → `bin/smoke` (quick sanity run) |
| "Smoke failed on adapter X / model Y" | Diagnose | `bin/smoke` (suggest) → `bin/troubleshoot X Y` (read logs, compat, version) |
| "Tool call signature broken?" | Deep dive | `bin/investigate` (pi/caveman triage) |
| "Track this incompatibility" | Document | `bin/troubleshoot --update-docs` (append to compat.json) |
| "Show me leaderboards" | Aggregate | `bin/report` (read results/) |
| "An incompatibility is stale (tool updated)" | Re-triage | `bin/troubleshoot` (version mismatch detected) → `bin/smoke` (rerun) |

**Key principle**: Each tool is a **single question**. Chains form user journeys, not command nesting.

## Out of scope (v1)

- Auto-fixing (driver's job)
- Updating adapter headers (manual edit)
- Running new trials (use `bin/smoke`)
- Deduplication of compat entries (plan for v2)
- Backprop §V invariants (separate skill)

## Implementation summary

**✅ Complete**:
1. Resolved 5 open questions & confirmed boundaries
2. Implemented `bin/troubleshoot` with all 7 concrete behaviors:
   - .bench.log last 50 lines (with highlights)
   - Adapter header extraction ("Known model incompatibilities")
   - compat.json lookup + version mismatch detection
   - Regression check (last successful run)
   - Suggested next action (based on compat status)
3. Integrated with `bin/smoke`: on failure, emit suggested troubleshoot command as copy-paste
4. `--update-docs` flag for recording incompatibilities
5. `--report` flag for markdown output

**Next**:
- Pilot on test combos: copilot+nemotron, caveman+lmstudio, opencode+nemotron
- Add §V invariant: "every documented compat entry must be reproducible via `bin/troubleshoot`"
- Dedup compat entries when count > 50 (v2)

## Related

- Memory: `troubleshoot-command-planning.md` (broader deferred note)
- Memory: `adapter-version-tracking.md` (version-in-header pattern this could verify)
- Memory: `reusable-tools-principle.md` (new command justified by border analysis above)
