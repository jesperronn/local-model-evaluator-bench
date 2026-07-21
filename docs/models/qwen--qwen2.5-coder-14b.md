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
accuracy: "aider 90.9% (40/44); pi 55.9% (19/34)"
speed_avg: "~16s median per case (aider); ~53s (pi)"
added: "2026-07-21"
last_run: "2026-07-21"
---

# qwen/qwen2.5-coder-14b

## Quick verdict

Accuracy and speed are co-equal signals — a fast model that fails, or an
accurate model that times out, is not usable. Both are reported below.

| Metric | Value |
|--------|-------|
| **Accuracy** | aider **90.9%** (40/44, full suite); pi **55.9%** (19/34) |
| **Speed (avg)** | aider ~16s median; pi ~53s |
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
all multifile JS (`js-03/04/05`), `bash-01`, `js-06`, and `ts-01`. The **full
12-case aider** run scored 40/44 (90.9%): 10 cases fully pass (incl. every
multifile/ts case pi failed), 2 partial (`bash-01` 1/4, `js-06` 3/4), no
failures and no timeouts. Most of the pi shortfall was adapter overhead, not the
model.

| Adapter | Result (32GB, 2026-07-21) | Speed | Runtime | Notes |
|---------|---------------------------|-------|---------|-------|
| aider | 40/44 (90.9%), full suite | ~16s median | lms | Recommended; recovers every pi failure |
| pi | 19/34 (55.9%), full suite | ~53s avg | lms | Fine single-file; fails multifile/bash/ts |
| hermes | 4/7 (57.1%), 4-case subset | ~120s median | lms | Poor pairing — slow, stalls/timeouts on multifile |

- **Working-adapters total:** aider 90.9% (full); pi 55.9% (full); hermes 57.1%
  (subset).
- **Overall incl. broken:** no adapters broken/unreachable. hermes reaches the
  model but is not recommended for it.
- hermes subset (`js-01/03/04/ts-01`): only `js-01` passed (4/4, 143s);
  `js-03` stalled (135s), `ts-01` timed out (152s), `js-04` failed (50s).

## Timing observations

- **Fastest adapter:** aider — 8–21s for most cases (smoke 8–10s, ts-01 13s);
  median 16s. Slowest aider case `js-05-multiselect-filter` at 44s.
- **Slowest adapter:** hermes — ~120s median, with a 135s stall and a 152s
  timeout on the subset. pi is next at ~53s average (worst case `js-05` hit the
  302s hard timeout before aider bounds were applied).
- **Slow cases (pi):** multifile JS (`js-03/04/05`) and `js-02-debounce` (78s).
- **Runtime note:** LM Studio (lms), MLX 4-bit; model load ~9s, ~7.75 GiB
  resident. No stalls or timeouts under aider (full suite, tight bounds).

## Failure patterns

- **pi, multifile edits** (`js-03/04/05`): repeatable — model produced code that
  failed the tests or timed out; these all pass under aider, so the cause is
  pi-adapter orchestration overhead on this model, not a model capability limit.
- **pi, `bash-01-topwords`**: repeatable — emitted an explanation plus a script
  that produced no output (`got []`). Not yet retested under aider.
- **pi, `ts-01-groupby`**: generated `groupBy` threw at runtime under pi; passes
  cleanly under aider.
- **aider, `bash-01-topwords`** (1/4) and **`js-06-lint-and-test`** (3/4):
  partial, repeatable — the only cases aider does not fully pass. `bash-01` is
  the model's weakest task across both adapters (shell script logic). No hard
  failures or timeouts under aider.
- **hermes**: poor pairing — 3/4 subset cases failed with slow responses,
  including a stall (`js-03`, 135s) and a timeout (`ts-01`, 152s). The adapter
  reaches the model but its orchestration is too heavy for this model here.

## Better alternatives

- `qwen/qwen3.5-9b` — smaller (~5.6 GB), 100% on aider, faster load; prefer it
  for the lightest reliable 32GB option.
- `google/gemma-4-26b-a4b-qat` — MoE (4B active), stronger on complex multifile.

Pick this 14B when you specifically want a dense Qwen2.5-Coder for single-file
and moderate multifile editing, driven by aider.

## Status

**keep** — a solid dense coder in the 32GB sizing sweet spot; recommended with
the aider adapter, where it scores 90.9% (full suite) fast and reliably.
Compare with sibling
`qwen/qwen2.5-coder-7b` (smaller/faster, lower ceiling) and `qwen/qwen3.5-9b`
(smaller, 100% on aider). See
[HARDWARE-RECOMMENDATIONS.md](../HARDWARE-RECOMMENDATIONS.md) for the 32GB
sizing rule this model was added under.
