# qwen/qwen3.5-9b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.5-9b` |
| **Family / arch** | Qwen3.5, dense, 9B |
| **Parameter count** | 9B |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-29 (run `20260629-025143`) |
| **Doc updated** | 2026-06-30 |

## Results summary

Strong small model. 2026-06-29 run: **aider and interpreter achieve 100%**, codex 97%, opencode and pi 92%, hermes 94%, goose and cline 89%, openhands 86%. caveman and copilot are LMS-incompatible. Overall 340/402 (84%); **93% excluding LMS-broken adapters**. Significant improvement vs the 2026-06-12 run where aider scored only 57.1%. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

| Adapter | 2026-06-29 (LMS) | Notes |
|---------|-----------------|-------|
| aider | 38/38 (100%) | Major improvement — previously 57.1% |
| interpreter | 38/38 (100%) | |
| codex | 37/38 (97%) | 1 case fail |
| hermes | 32/34 (94%) | 2 cases fail |
| opencode | 35/38 (92%) | 3 cases fail |
| pi | 35/38 (92%) | |
| goose | 34/38 (89%) | |
| cline | 34/38 (89%) | |
| openhands | 33/38 (86%) | |
| caveman | 12/32 (37%) | LMS incompatible |
| copilot | 12/32 (37%) | LMS incompatible |

## Failure patterns

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails; codex, opencode, caveman all pass 3/3. Same aider multi-file format issue seen across all models.

**Adapter-specific — aider, js-05-multiselect-filter (0/1):** aider fails the self-verify filter case (0/1) while opencode, codex, caveman all score 5/5. The model does not iterate under aider's prompting style.

**Soft failure — aider, js-01-slugify-bug (2/4):** aider scores 2/4. The model fixes part of the slug logic but misses the edge cases for consecutive hyphens or leading/trailing hyphens.

**Soft failure — aider, js-03-multifile-cache (1/5):** aider scores 1/5 — model partially applies the cache implementation but misses later sub-tests.

**Adapter-specific — opencode, bash-01-topwords (0/4):** opencode fails the bash pipeline case (0/4) while aider, codex, caveman all score 4/4. This is unusual — opencode passes bash-01 on most other models. Likely a prompt-format interaction where the model doesn't produce a shell pipeline in opencode's expected format for this case.

**Caveman timeout — js-02-debounce-feature (0/1, timeout 300s):** caveman hit the 300s limit on js-02 and scored 0/1. This is likely a genuine timeout — the model got stuck iterating or producing very long output. Codex and opencode pass this case.

**Codex lingering — bash-01-topwords (4/4, timeout 300s):** codex scored 4/4 but hit the timeout limit — it applied the correct edit but didn't exit cleanly. The edit was correct; this is a codex lingering issue.

## Timing observations

- **aider:** 12–29s. Fastest adapter.
- **opencode:** 8–131s. js-06 took 131s (self-verify iteration). bash-01 failed quickly.
- **codex:** 32–300s. bash-01 hit timeout but passed; ts-01 was 149s.
- **caveman:** 19–300s. js-02 timed out (genuine failure); other cases 19–132s.

## Observations across runs

### 2026-06-29 — LMS overnight (run `20260629-025143`)

Full 11-adapter sweep on LMS. aider improved dramatically from 57.1% (2026-06-12) to 100% — all multifile cases now pass. interpreter also 100%. The model shows strong across-the-board capability with the 9B scale. caveman and copilot confirmed LMS-incompatible. Slower adapters (cline, goose, openhands) have a few misses likely from timeout pressure.

## MLX runtime results (2026-06-12)

hermes via `mlx_lm.server`: **34/34 (100%)** — all 9 cases passed. No cold-start JIT issue
(unlike Qwen3-Coder-30B — the 9B model's JIT compiles before the first request).
js-03-multifile-cache status=timeout at 300s but all 5 tests passed before the adapter
was killed. Timing: 24–300s per case, avg 153s — approximately 1.1× slower than LMS hermes
(137s avg), much less overhead than the 30B model's 2.5× MLX penalty.

## Known issues

**Caveman timeout on js-02:** intermittent risk. Run with `--trials 3` to check reproducibility.

## Status

**keep** — solid results on codex and caveman; the aider gap is a known format issue. The caveman js-02 timeout is worth monitoring.

## Suggested experiment

Run `--trials 3` for caveman on this model to check whether the js-02 timeout is reproducible or a one-off.
