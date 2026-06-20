# google/gemma-4-12b

## Metadata

| Field | Value |
|-------|-------|
| **Status** | AVOID — unusable tool calling (13.6%, infra failures + capability gap) |
| **Model key** | `google/gemma-4-12b` |
| **Family / arch** | Gemma 4, dense, 12B (fp16) |
| **Parameter count** | 12B |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **Doc updated** | 2026-06-09 |

## Results summary

Partial data only. aider ran with meaningful results (36%) but all other adapters either crashed (error(1)) or scored near-zero in under 2 seconds with ok status — indicating a model-loading or connection failure at run time, not a capability assessment. Results are not comparable to other models. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Infrastructure failure — codex, caveman (error(1), 1–10s):** codex and caveman both exit with error(1) in under 10s on all cases. This matches the pattern of adapters that cannot connect to the model. Likely the model was not loaded in LM Studio during this portion of the run, or the model key didn't match.

**Infrastructure failure — opencode (ok status, 0–4s, score=0):** opencode exits cleanly (ok status) but in 0–4s with 0 pass on all cases except js-01 (2/4). This is consistent with a zero-length or boilerplate response — the model may have been partially responsive but generating empty output.

**Genuine aider results — low but real:** aider ran with non-trivial times (10–300s) and produced a few passes (9/25 = 36% excluding smoke). Two timeouts (bash-01 at 300s, js-03 at 300s). This is genuine model output, just weak. The aider results suggest the model is slow and struggles with multi-file cases when actually running.

## Timing observations

aider-only: 10–300s per case. All other adapters: 0–15s (infrastructure failures).

## Known issues

**Run contamination:** codex, caveman, opencode results are almost certainly infrastructure failures. The model was likely unloaded or the key mismatched mid-run. These results should not be used to assess model capability on those adapters.

## Status

**avoid** — broken/unusable tool calling. Overall score 13.6% (19/140), but this combines genuine aider results (36%) with infrastructure-failure zeros across codex, caveman, and opencode. Even the "genuine" aider results (36%) are too weak to be useful — two timeouts and consistent failures on multi-file and self-verify cases. The QAT sibling (`google/gemma-4-12b-qat`) scored 59.9% with clean infrastructure but was removed for being dominated by `qwen/qwen3.5-9b`. This fp16 variant has both a capability gap and a tool-calling reliability problem.

**Cleanup:** remove `google/gemma-4-12b` from `models.txt` and unload from LM Studio. If you need a 12B Gemma, prefer `google/gemma-4-12b-qat` — but note that model was also removed as dominated; `qwen/qwen3.5-9b` is the better alternative at this size.

See also: [Models to Avoid in LEADERBOARD.md](../../LEADERBOARD.md#models-to-avoid)
