---
title: "qwen/qwen2.5-coder-14b"
model_key: "qwen/qwen2.5-coder-14b"
family: "Qwen2.5-Coder"
params_total: "14B"
params_active: "14B"
quantization: "MLX 4-bit"
disk_size: "~8.33 GB (7.75 GiB resident)"
context: "65k tested (native 32k+)"
status: "keep"
recommended_for: ["32gb", "64gb"]
tier: "32gb"
best_adapter: "aider"
accuracy: "aider 100% (4/4 subset); pi 55.9% (19/34)"
speed_avg: "~12-21s per case (aider); ~53s (pi)"
added: "2026-07-21"
last_run: "2026-07-21"
---

# qwen/qwen2.5-coder-14b

## Quick verdict

Accuracy and speed are co-equal signals — a fast model that fails, or an
accurate model that times out, is not usable. Both are reported below.

| Metric | Value |
|--------|-------|
| **Accuracy** | aider **100%** (4/4 subset incl. multifile/ts); pi **55.9%** (19/34) |
| **Speed (avg)** | aider ~12–21s; pi ~53s |
| **Best adapter** | **aider** — recovers every case pi fails, and faster |
| **Recommended for** | 32GB / 64GB — surgical + multifile edits when driven by aider |
| **Status** | keep |

Dense 14B coder at MLX 4-bit (8.33 GB) that fits the 32GB sizing sweet spot
(leaves room for context + OS). Capability is adapter-bound: excellent under
**aider**, mediocre under **pi**.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen2.5-coder-14b` |
| **Family / arch** | Qwen2.5-Coder, dense |
| **Parameter count** | 14B total / 14B active (dense) |
| **Quantization** | MLX 4-bit |
| **Disk size** | ~8.33 GB (7.75 GiB resident, measured 2026-07-21) |
| **Context window** | 65k tested (BENCH_CONTEXT=65536) |
| **Load time** | ~9s on M2 Max 32GB |
| **Added** | 2026-07-21 |
| **Last run** | 2026-07-21 (runs `20260721-224107` pi, `20260721-225546` aider) |
| **Doc updated** | 2026-07-21 |

Prompt template: multi-role prompting works — smoke reached the model on both
the pure text path (`smoke-00-hello`) and the tool-call/edit path
(`smoke-01-edit-file`) with no template errors.

## Results summary

**Adapter choice is decisive.** Under `pi` the full 12-case suite scored 19/34
(55.9%): it handled smoke cases, `deleg-01`, and simple JS (`js-01`), but failed
all multifile JS (`js-03/04/05`), `bash-01`, `js-06`, and `ts-01`. Re-running
the failing cases under **aider** flipped the result to 4/4 — including the exact
`js-03`, `js-04`, and `ts-01` that pi failed — confirming most of the pi
shortfall was adapter overhead, not the model.

| Adapter | Result (32GB, 2026-07-21) | Speed | Runtime | Notes |
|---------|---------------------------|-------|---------|-------|
| aider | 4/4 subset (100%) | ~12–21s | lms | Recommended; recovers every pi failure |
| pi | 19/34 (55.9%) | ~53s avg | lms | Fine single-file; fails multifile/bash/ts |

- **Working-adapters total:** aider 100% (subset); pi 55.9% (full suite).
- **Overall incl. broken:** no adapters were broken/unreachable in these runs.
- aider was run on a 4-case subset (`js-01`, `js-03`, `js-04`, `ts-01`) with
  tight bounds (`--timeout 120 --stall 60 --warmup 90`) to avoid timeout waits;
  a full 12-case aider run is the natural next step.

## Timing observations

- **Fastest adapter:** aider — 12–21s per case (js-04 and ts-01 at 12s each).
- **Slowest adapter:** pi — ~53s average; worst case `js-05` hit the 302s hard
  timeout before aider bounds were applied.
- **Slow cases (pi):** multifile JS (`js-03/04/05`) and `js-02-debounce` (78s).
- **Runtime note:** LM Studio (lms), MLX 4-bit; model load ~9s, ~7.75 GiB
  resident. No stalls or timeouts under aider with tight bounds.

## Failure patterns

- **pi, multifile edits** (`js-03/04/05`): repeatable — model produced code that
  failed the tests or timed out; these all pass under aider, so the cause is
  pi-adapter orchestration overhead on this model, not a model capability limit.
- **pi, `bash-01-topwords`**: repeatable — emitted an explanation plus a script
  that produced no output (`got []`). Not yet retested under aider.
- **pi, `ts-01-groupby`**: generated `groupBy` threw at runtime under pi; passes
  cleanly under aider.
- Under **aider**: no failures observed in the 4-case subset.

## Better alternatives

- `qwen/qwen3.5-9b` — smaller (~5.6 GB), 100% on aider, faster load; prefer it
  for the lightest reliable 32GB option.
- `google/gemma-4-26b-a4b-qat` — MoE (4B active), stronger on complex multifile.

Pick this 14B when you specifically want a dense Qwen2.5-Coder for single-file
and moderate multifile editing, driven by aider.

## Status

**keep** — a solid dense coder in the 32GB sizing sweet spot; recommended only
with the aider adapter, where it is fast and reliable. Compare with sibling
`qwen/qwen2.5-coder-7b` (smaller/faster, lower ceiling) and `qwen/qwen3.5-9b`
(smaller, 100% on aider). See
[HARDWARE-RECOMMENDATIONS.md](../HARDWARE-RECOMMENDATIONS.md) for the 32GB
sizing rule this model was added under.
