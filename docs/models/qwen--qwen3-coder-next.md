# qwen/qwen3-coder-next

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3-coder-next` |
| **Family / arch** | Qwen3-Coder, dense or MoE <!-- TODO: confirm arch --> |
| **Parameter count** | <!-- TODO --> |
| **Disk size** | 60.31 GiB (as reported by `lms load`, 2026-06-09) |
| **Added** | 2026-06-09 |
| **Last run** | 2026-06-09 |

## Results summary

Strong coding model that scores 100% on codex and 96.7% on caveman. The headline result is that **opencode crashes with error(1) on every case** (all 9 cases, ~1s each), making opencode data useless for this model until the compatibility issue is resolved. Excluding broken adapters, it is on par with qwen3-coder-30b. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Adapter-specific — aider, bash-01-topwords (0/4):** aider fails the bash CLI case across all runs while codex and caveman score 4/4. The model produces a valid solution but aider's diff format isn't applied correctly — likely the model emits whole-file output rather than the search/replace blocks aider expects.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails this multi-file rename case while codex and caveman pass 3/3. Same suspected mechanism: aider's file-targeting requires explicit `--file` hints; the model edits only one of the two files.

**Soft failure — aider, js-03-multifile-cache (1/5):** aider scores 1/5 here, suggesting the model makes one correct sub-edit but misses the rest. caveman also fails (0/1), while codex passes 5/5. The case requires atomic edits across ≥2 files; both aider and caveman appear to drop one of the edits.

**Broken — opencode, all cases (error(1), ~1s):** opencode exits with rc=1 in under 2 seconds on every case. This is not a model-quality issue — codex and caveman show the model is capable. Likely a model-key or API-response format incompatibility introduced in this model version. Compare: opencode scored 97.1% with qwen3-coder-30b.

**Broken — hermes, all cases (error(1), ~4s):** hermes fails identically to opencode. Hermes is broken across all models; this is an adapter-level issue.

## Timing observations

- **codex:** 45–263s per case. js-03-multifile-cache took 263s (longest). All ok, no timeouts.
- **caveman:** 22–70s. Consistently faster than codex at comparable quality.
- **aider:** 10–52s. Fastest of the working adapters. js-05 took 52s (self-verify iteration).
- **opencode / hermes:** 0–5s (crash, not real work).

## Known issues

**opencode error(1) — every case:** opencode fails immediately with non-zero exit on every case. The failure is deterministic and adapter-wide, not case-specific. Suspected: `lmstudio/<model-id>` routing fails because qwen3-coder-next doesn't appear in opencode's model catalogue or the response format changed. Investigate `~/.config/opencode/opencode.json` and opencode debug logs.

## Status

**rerun** — opencode compatibility needs to be debugged before this model's full adapter matrix can be evaluated. Once opencode is fixed, re-run to get comparable data across all adapters. Trigger: resolve opencode error(1) and re-run with `--tool opencode`.

## Comparison within family

Compared to qwen3-coder-30b on the working adapters:
- codex: identical (100% both)
- caveman: 96.7% vs 100% (coder-next drops js-03-multifile-cache)
- aider: 71.9% vs 81.2% (slight regression)
- caveman is noticeably faster on coder-next (22–70s vs 46–127s)
