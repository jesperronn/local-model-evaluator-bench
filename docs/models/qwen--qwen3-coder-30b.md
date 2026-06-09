# qwen/qwen3-coder-30b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3-coder-30b` |
| **Family / arch** | Qwen3-Coder, MoE (30B total, ~3B active) |
| **Parameter count** | 30B total, ~3B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |

## Results summary

One of the top-performing models in the suite. opencode, codex, and caveman all achieve ≥97% — opencode 97.1%, codex 100%, caveman 100%. aider trails at 81.2% due to adapter-format friction on multi-file cases. Second only to qwen3.6-35b-a3b on non-aider adapters, and faster than it. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails while all other adapters pass 3/3. aider doesn't receive explicit file hints; the model edits only one file, breaking the ESM import chain.

**Soft failure — aider, js-03-multifile-cache (1/5):** aider scores 1/5 on the multi-file cache case while codex and caveman score 5/5. The model partially completes the edit, likely missing one of the two files.

**Soft failure — aider, js-06-lint-and-test (3/4):** aider scores 3/4 (75%) on the self-verify lint case. The model passes lint and 3 of 4 tests but doesn't fix the last failing test despite iterating.

**Adapter-specific — opencode, bash-01-topwords (3/4):** opencode scores 3/4 (75%) where codex and caveman score 4/4. The model produces a correct pipeline for 3 of 4 input variations but one edge case (likely empty-line handling or locale sort) fails.

**Status note — codex js-06, ts-01 (error(1) with full pass):** codex scored 4/4 on js-06 and 3/3 on ts-01 but logged error(1) status. The edit was applied correctly; codex exited non-zero after finishing. This is a codex lingering/exit-code issue, not a model failure.

## Timing observations

- **aider:** 6–24s. Very fast; benefits from MoE's low active-parameter count.
- **opencode:** 20–158s. js-05 (self-verify) took longest at 158s.
- **codex:** 49–142s. Comparable to qwen3-coder-next but slightly faster on most cases.
- **caveman:** 18–127s. Slower than aider but more reliable on multi-file cases.

## Known issues

**hermes error(1) — all cases:** hermes fails on all models; adapter-level issue unrelated to this model.

**codex non-zero exit on js-06, ts-01:** codex exits with rc=1 after successfully applying edits. No data loss — grader scored full points. Likely a codex CLI bug (fails to clean up a subprocess). Monitor across runs.

## Status

**keep** — stable, comprehensive results across 4 working adapters. Strong baseline for the Qwen3-Coder family. Re-run if a new qwen3-coder-30b variant appears in LM Studio.

## Comparison within family

qwen3-coder-30b vs qwen3-coder-next (both are Qwen3-Coder family):
- On codex/caveman: near-identical quality, but coder-next is notably faster with caveman
- coder-next has opencode broken (error(1)); coder-30b opencode works at 97.1%
- For production use: prefer coder-30b until opencode compatibility is restored for coder-next
