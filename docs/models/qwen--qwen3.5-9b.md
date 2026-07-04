# qwen/qwen3.5-9b

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% (aider on 32GB) |
| **Speed (avg)** | ~24s per case (aider) |
| **Best adapter** | aider — reliable and fast on 32GB tier |
| **Recommended for** | general agentic coding, multi-file edits; excellent choice for resource-constrained 32GB environments |
| **Status** | keep |

## Better alternatives

None specifically identified as strictly better for the 32GB tier. Qwen3.6 variants (e.g., 27B/35B) may offer higher accuracy on harder tasks but require more RAM.

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.5-9b` |
| **Family / arch** | Qwen3.5, dense, 9B |
| **Parameter count** | 9B |
| **Disk size** | ~5.57 GiB (measured 2026-07-04) |
| **Added** | 2026-06-08 |
| **Last run** | 2026-07-04 (run `20260704-113219`, 32GB tier) |
| **Doc updated** | 2026-07-04 |

## Results summary

Excellent small-model performer on 32GB hardware. 2026-07-04 run on 32GB tier: **aider 100% (21/21 cases, ~24s avg)**, cline 80% (17/21, hits 300s timeout on harder cases), openhands 67% (14/21), codex incomplete (2/7 cases). Strong compact model — loads in ~6s, efficient 9B dense architecture. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

| Adapter | 2026-07-04 (32GB) | Notes |
|---------|-----------------|-------|
| aider | 21/21 (100%) | Recommended for 32GB tier — fastest, most reliable |
| cline | 17/21 (80%) | Works but slow; 3 cases hit 300s timeout (bash-01, js-02, ts-01) |
| openhands | 14/21 (66%) | Fails bash-01-topwords; variable timing |
| codex | 2/7 (incomplete) | Interrupted; not re-run; excluded from 32GB recommendation |

### Prior runs

**2026-06-29 run**: aider and interpreter achieve 100% across full 38-case suite; codex 97%, opencode and pi 92%, hermes 94%, goose and cline 89%, openhands 86%. Overall 340/402 (84%); **93% excluding LMS-broken adapters** (caveman, copilot).

## Failure patterns (32GB run, 2026-07-04)

**Cline timeout pressure — bash-01-topwords, js-02-debounce-feature, ts-01-groupby (3 cases, 300s limit):** cline consistently hits the 300s timeout on these cases — bash-01 status=timeout (303s), js-02 partial (1/4, 301s), ts-01 status=timeout (302s). The model is functional but slow on complex cases; on simpler cases (smoke-*, js-01) it performs well (avg 16–43s).

**Openhands bash-01-topwords (0/4, 56s):** openhands fails the bash pipeline case completely (0/4) while aider passes 4/4. Likely a prompt-format interaction or tool-use mismatch.

**Openhands js-01-slugify-bug (2/4, 46s):** partial success — model fixes part of the logic but misses edge cases.

**Openhands js-02-debounce-feature (3/4, 12s):** mostly succeeds but 1 sub-test fails.

**Codex incomplete run:** only 2 of 7 cases completed before interruption (bash-01 100%, js-01 75%). Not evaluated for recommendation.

### Prior failure patterns (from 2026-06-29 full suite)

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails multi-file format; codex, opencode, caveman all pass 3/3. Same issue seen on qwen3-coder-30b.

**Adapter-specific — aider, js-05-multiselect-filter (0/1):** aider fails self-verify iteration; opencode, codex pass 5/5 each.

**Soft failure — aider, js-01-slugify-bug (2/4):** model fixes part but misses edge cases.

**Soft failure — aider, js-03-multifile-cache (1/5):** partial application, misses later sub-tests.

## Timing observations (32GB run, 2026-07-04)

- **aider:** 13–34s, avg 24s. Fastest and most reliable — excellent for 32GB constraints.
- **cline:** 21–303s, avg 188s. Fast on simple cases (smoke-*, js-01: 21–43s) but hits timeout pressure on harder cases (bash-01: 303s timeout, js-02: 301s timeout, ts-01: 302s timeout).
- **openhands:** 12–242s, avg 75s. Moderate speed but incomplete accuracy; ts-01 slowest (242s).
- **codex:** incomplete (only bash-01: 67s, js-01: 56s completed before interruption).

### Prior timing (2026-06-29 full suite)

- **aider:** 12–29s. Fastest adapter.
- **interpreter:** avg 78s, consistent across cases.
- **cline:** 89% pass rate, slower iteration profile.
- **openhands:** 86% pass rate, avg 90+ seconds.

## Observations across runs

### 2026-07-04 — 32GB tier benchmark (run `20260704-113219`)

Focused evaluation on 32GB hardware (typical for production deployments). **aider is the clear winner: 100% pass, ~24s avg — ideal for resource-constrained environments.** cline is functional but slow (300s timeout hits on 3 cases), openhands struggles with bash tasks (67% overall). This model is an excellent default for 32GB machines where speed and reliability matter; aider keeps response latency under 35s even for moderately complex cases. Codex run incomplete; excluded from recommendation.

### 2026-06-29 — LMS overnight (run `20260629-025143`)

Full 11-adapter sweep on LMS. aider improved dramatically from 57.1% (2026-06-12) to 100% — all multifile cases now pass. interpreter also 100%. The model shows strong across-the-board capability with the 9B scale. caveman and copilot confirmed LMS-incompatible. Slower adapters (cline, goose, openhands) have a few misses likely from timeout pressure.

## MLX runtime results (2026-06-12)

hermes via `mlx_lm.server`: **34/34 (100%)** — all 9 cases passed. No cold-start JIT issue
(unlike Qwen3-Coder-30B — the 9B model's JIT compiles before the first request).
js-03-multifile-cache status=timeout at 300s but all 5 tests passed before the adapter
was killed. Timing: 24–300s per case, avg 153s — approximately 1.1× slower than LMS hermes
(137s avg), much less overhead than the 30B model's 2.5× MLX penalty.

## Known issues

**Cline 300s timeout on hard cases:** bash-01-topwords, js-02-debounce-feature, ts-01-groupby all hit or exceed 300s with cline. This is systematic, not intermittent — likely due to cline's slower iteration strategy on this 9B model. Do not use cline for 32GB production deployments; **aider is strongly preferred.**

**Openhands bash case failure:** openhands fails bash-01-topwords completely (0/4) across all contexts. Likely a tool-use or prompt-format mismatch, worth investigation if openhands is needed for other reasons.

## Status

**keep — aider is the recommended 32GB default.** Excellent small-model choice for resource-constrained environments: 100% accuracy, ~24s per case, loads in ~6s. Codex run incomplete (not evaluated). cline too slow for 32GB tight timeout budgets. openhands too unreliable (67%).

## Recommended config for 32GB tier

```bash
# config.sh or agent config apply
MODEL_PRIMARY=qwen/qwen3.5-9b
ADAPTER_DEFAULT=aider
BENCH_PARALLEL=3          # allows 2–3 concurrent aider runs without OOM
```
