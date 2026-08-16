---
title: "DeepSeek-V4-Flash-2bit-DQ (oMLX)"
model_key: "DeepSeek-V4-Flash-2bit-DQ"
family: "DeepSeek V4"
params_total: "30B"
params_active: "unknown (MoE, active-param count not published for this quant)"
quantization: "MLX 2-bit dynamic quantization (DQ)"
disk_size: "~90 GiB"
context: "1048576 (1M native)"
status: "watch"
recommended_for: ["long-context-tasks"]
tier: "128gb"
best_adapter: "pi"
accuracy: "100% (pi, excl. smoke-00); 68.4% (caveman); 68.4% (aider); 36.1% (opencode)"
speed_avg: "~240s per case (pi); ~257s (aider); ~162s (caveman); ~167s (opencode)"
added: "2026-08-16"
last_run: "2026-08-16 (20260816-192935 caveman/pi, 20260816-205238 opencode, 20260816-212840 aider)"
---

# DeepSeek-V4-Flash-2bit-DQ

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | pi 100% (42/42); caveman 68.4% (26/38); aider 68.4% (26/38); opencode 36.1% (13/36) — all excl. smoke-00 |
| **Speed (avg)** | caveman ~162.0s/case (fastest); opencode ~167.3s/case; pi ~239.8s/case; aider ~256.6s/case (slowest, tied for 2nd-best accuracy) |
| **Best adapter** | pi — the only adapter with a clean sweep; caveman, aider, and opencode all stall or timeout repeatedly on this model |
| **Recommended for** | long-context tasks where the 1M-token window matters and pi's slower pace is acceptable; NOT yet a general daily driver given three of four adapters underperform |
| **Status** | watch — promising ceiling (pi 100%), but adapter compatibility is inconsistent enough to hold off on "keep" |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `DeepSeek-V4-Flash-2bit-DQ` (oMLX directory basename; HF source: `mlx-community/DeepSeek-V4-Flash-2bit-DQ`) |
| **Family / arch** | DeepSeek V4 Flash 0731, MoE with hybrid CSA/HCA attention — a new architecture family not covered by mainline `mlx-lm` at the time of writing ([mlx-lm issue #1281](https://github.com/ml-explore/mlx-lm/issues/1281)); oMLX added native support across a run of 0.5.4–0.5.8 hotfixes culminating in the "official Flash 0731 reference encoder" in 0.5.7. |
| **Parameter count** | 30B total (per HF listing); active-parameter count for this specific quant is not published |
| **Quantization** | MLX 2-bit dynamic quantization (DQ) |
| **Disk size** | ~90 GiB (89.99 GB reported by oMLX at load) |
| **Context window** | 1,048,576 tokens (1M) native — by far the largest context window in this repo's model set |
| **Added** | 2026-08-16 |
| **Last run** | 2026-08-16 (caveman/pi: run 20260816-192935; opencode: run 20260816-205238, re-run after fixing a config gap — see Failure patterns; aider: run 20260816-212840) |
| **Doc updated** | 2026-08-16 |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| pi | 100% (42/42) | ~239.8s | omlx | Clean sweep, no failures — including two cases that hit the 600s timeout ceiling on other runs elsewhere in this repo. Slowest per-case average of the three, but the only adapter with zero stalls. |
| caveman | 68.4% (26/38) | ~162.0s | omlx | Fastest, but stalls on 4/12 cases (see Failure patterns). |
| opencode | 36.1% (13/36) | ~167.3s | omlx | Stalls on 8/12 cases, including trivial ones (`smoke-00-hello`, `smoke-02-numbers`) — see Failure patterns for the config issue this run uncovered and the separate stall pattern that persisted after fixing it. |
| aider | 68.4% (26/38) | ~256.6s | omlx | Slowest average, but ties caveman for 2nd place on accuracy; 3 hard cases hit the full 600s timeout ceiling outright (see Failure patterns). |

**Working adapters total:** 4/4 benched
**Overall (4 adapters, incl. broken/stalled, excl. smoke-00):** 107/154 (69.5%)

## Timing observations

- pi is markedly slower per case (~240s avg) than caveman/opencode (~162-167s avg) but is the only adapter that reliably completes every case — two pi cases (`bash-01-topwords`, `js-02-debounce-feature`) ran the full 601s before finishing, right at this run's timeout ceiling, yet still scored 100%.
- caveman and opencode both show a repeating ~121-123s stall signature on their failing cases — suspiciously close to the bench harness's 120s stall-watchdog default, suggesting these adapters' tool-call round-trip with this model's native DSML tool-call format is slow enough to blow the watchdog before a sandbox file gets touched, rather than the model failing to reason about the task at all. Worth revisiting with a longer `--stall` budget before concluding these adapters are incompatible outright.
- Model load itself takes ~10s once oMLX has the weights resident on SSD-backed cache (see server log timestamps at load); this is separate from and much smaller than the per-case generation time.
- This model's 1M context window is far beyond what any of the current cases exercise — none of the timing or stall issues observed here are attributable to context length.

## Failure patterns

- **opencode, config gap (fixed 2026-08-16):** the model was never registered in opencode's local model list (`~/.config/opencode/opencode.jsonc`'s `omlx` provider block only lists models present at the last `bin/agents-config --write`). Every opencode request in the first attempt failed instantly (~2s) with `UnknownError: Unexpected server error` — before the model was ever invoked, and with zero corresponding server-side log entries confirming the requests were rejected before generation. Fixed by re-running `bin/agents-config --write`, which added the missing entry. **This is a required step whenever a new model is added to oMLX and opencode is one of the adapters under test — it is not automatic.**
- **opencode, post-fix stall pattern:** even after the config fix, opencode stalls (0-score, ~121-123s) on 8/12 cases, including trivial ones (`smoke-00-hello`, `smoke-02-numbers`). Server logs confirm the model IS responding (`finish_reason=tool_calls` / `stop` entries appear during opencode's window), so this is not a repeat of the config issue — it looks like opencode's handling of this model's DSML tool-call format is slow or lossy enough that no sandbox file gets written before the watchdog fires. Not yet root-caused to the DSML parser specifically; flagged for follow-up rather than concluded.
- **caveman, 4/12 stalls:** `bash-01-topwords`, `js-05-multiselect-filter`, `js-06-lint-and-test`, `ts-01-groupby` all stall at ~121-123s — the same signature as opencode's failures, on a different but overlapping set of harder/self-verify cases. Consistent with a shared adapter-side slowness against this model's tool-call format rather than two unrelated bugs.
- **aider, 3/12 full timeouts:** `bash-01-topwords`, `js-05-multiselect-filter`, `js-06-lint-and-test` all ran the full 601s before being killed — notably the same three cases (plus `ts-01-groupby`, which aider actually passed at 44s) that give caveman and opencode trouble, reinforcing that these specific cases are hard on this model regardless of adapter. Unlike caveman/opencode's ~120s stalls, aider's failures burn the full timeout — a difference in how each adapter's watchdog/retry behavior interacts with a slow-responding model, not evidence of a different underlying problem. `js-03-multifile-cache` (3/5, also a 601s timeout) was a partial pass despite hitting the ceiling.
- **pi, no failures:** the only adapter with a clean run. Two cases ran to the 601s timeout ceiling but still completed successfully, suggesting pi's harness tolerates this model's slower/verbose tool-call turns better than the other three adapters do — the same "burn the timeout but still finish" behavior that aider showed on `js-03-multifile-cache`, just working out in pi's favor across the board.

## Better alternatives

- For correctness-critical work at a similar footprint on this machine, `qwen3.8:27b-mlx` (ollama) currently has a cleaner track record across more adapters (91.1% blended, 3/4 adapters at 100%) — see [qwen--qwen3.8-27b-mlx.md](qwen--qwen3.8-27b-mlx.md). DeepSeek V4 Flash's 1M context is the differentiator if that window is actually needed.
- No other model in this repo's fleet currently offers anywhere near this context window, so there's no direct substitute for long-context tasks specifically.

## Status

**watch** — pi's clean 100% sweep is a strong signal the model itself is capable, but caveman, aider, and opencode all show real, reproducible stall/timeout patterns on the same handful of hard cases (`bash-01-topwords`, `js-05-multiselect-filter`, `js-06-lint-and-test`) that need more investigation (longer `--stall`/`--timeout` budget, and/or a closer look at DSML tool-call handling in the non-pi adapters) before this can be called "keep." Full 4-adapter matrix is now complete.

## Comparison within family

| Variant | Runtime | Accuracy (excl. smoke-00) | Avg speed | Verdict |
|---|---|---|---|---|
| `DeepSeek-V4-Flash-2bit-DQ` (mlx-community) | omlx | pi 100% / caveman 68.4% / aider 68.4% / opencode 36.1% | 162-257s (adapter-dependent) | **watch** — no other DeepSeek V4 variant benched yet in this repo |

## Observations across runs

- 2026-08-16: initial bench, full 4-adapter matrix. Confirmed oMLX 0.6.0 loads and serves this model natively (no `ds4`/DwarfStar engine needed, contrary to the original T13 backlog assumption — see `TASKS.md`). Smoke tests passed clean before the full matrix. caveman/pi/opencode ran together in one `bin/bench` invocation (single model load, no unload race between adapters — see `lib/common.sh`'s `omlx_unload_model` fix, filed as T19 in `TASKS.md`); aider ran as a separate invocation afterward. opencode's first attempt was invalidated by a missing `bin/agents-config --write` step; re-run after the fix surfaced a separate, real stall pattern rather than resolving to a clean score. Across all three non-pi adapters, the same small set of cases (`bash-01-topwords`, `js-05-multiselect-filter`, `js-06-lint-and-test`) accounts for most of the failures, suggesting these specific cases are genuinely hard for this model under tool-calling adapters generally, not an adapter-specific quirk each time.
