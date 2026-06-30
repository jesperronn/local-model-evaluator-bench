# qwen/qwen3-coder-30b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3-coder-30b` |
| **Family / arch** | Qwen3-Coder, MoE (30B total, ~3B active) |
| **Parameter count** | 30B total, ~3B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-29 (run `20260629-235247`) |
| **Doc updated** | 2026-06-30 |
| **Workarounds needed** | **shim — pi edit-tool XML recovery** (safety net for flat-XML tool-call paths that can't encode nested `edits:[{oldText,newText}]`; **path-dependent — not reproduced on the bench's structured-tool_calls path**, see [tools/pi.md](../tools/pi.md) and [SCORING.md](../SCORING.md#workarounds-and-fairness)). None known for codex / opencode / aider. |

## Results summary

One of the top-performing models in the suite. 2026-06-29 full sweep on LMS: aider/interpreter/goose **100%**, pi 97%, codex/hermes/openhands 92%. caveman LMS-incompatible. Overall 276/306 across 8 tested adapters; **97% excl caveman**. Second only to qwen3.6-35b-a3b on overall accuracy, notably faster per token (MoE 3B active). See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

| Adapter | 2026-06-29 (LMS) | Notes |
|---------|-----------------|-------|
| aider | 38/38 (100%) | Fastest adapter — avg 11s, range 6–24s |
| interpreter | 38/38 (100%) | avg 78s, range 4–301s |
| pi | 37/38 (97%) | bash-01 WARN 3/4 |
| codex | 35/38 (92%) | ts-01 error(1) |
| hermes | 35/38 (92%) | bash-01 WARN, 2 smoke WARNs |
| openhands | 35/38 (92%) | bash-01 WARN, js-03 stall |
| goose | 38/38 (100%) | avg 105s, range 6–302s |
| nanocoder | 36/38 (95%) | bash-01 4/4 PASS (only model to do so); smoke-01 0/2 |
| caveman | 12/32 (37%) | LMS incompatible |
| cline | not run | — |
| opencode | not run | — |

## Failure patterns

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails while all other adapters pass 3/3. aider doesn't receive explicit file hints; the model edits only one file, breaking the ESM import chain.

**Soft failure — aider, js-03-multifile-cache (1/5):** aider scores 1/5 on the multi-file cache case while codex and caveman score 5/5. The model partially completes the edit, likely missing one of the two files.

**Soft failure — aider, js-06-lint-and-test (3/4):** aider scores 3/4 (75%) on the self-verify lint case. The model passes lint and 3 of 4 tests but doesn't fix the last failing test despite iterating.

**Adapter-specific — opencode, bash-01-topwords (3/4):** opencode scores 3/4 (75%) where codex and caveman score 4/4. The model produces a correct pipeline for 3 of 4 input variations but one edge case (likely empty-line handling or locale sort) fails.

**Status note — codex js-06, ts-01 (error(1) with full pass):** codex scored 4/4 on js-06 and 3/3 on ts-01 but logged error(1) status. The edit was applied correctly; codex exited non-zero after finishing. This is a codex lingering/exit-code issue, not a model failure.

**Tool-format incompatibility — pi `edit` tool, PATH-dependent (2026-06-25):** on a flat-XML tool-call path the model emits `<parameter=NAME>` XML that can't encode pi's nested `edits:[{oldText,newText}]` param; the parser mangles it, pi rejects it (`edits.0 must be object`), and the model recovers via `write`. **Not intrinsic to qwen3-coder:** a captured bench trace shows it emitting a clean nested `edit` via `pi --provider lmstudio` (structured tool_calls). The trigger is the client/template path, not the model — see [tools/pi.md](../tools/pi.md). Fixed for scoring with a recovery shim, now applied automatically by all pi/caveman adapters (see [tools/pi.md](../tools/pi.md)). Likely affects other Hermes-format qwen models (qwen2.5-coder, qwen3.6-35b) — **untested**. Note: `smoke-01-edit-file` *cannot* detect this by score (the model recovers via `write` and still scores 1.00); breadth must be confirmed by inspecting tool-call traces, not pass-rate.

## Timing observations

- **aider:** avg 11s, range 6–24s. Fastest adapter by far. MoE 3B active makes this model extremely responsive.
- **interpreter:** avg 78s, range 4–301s. js-03-multifile-cache hit 301s (right at timeout) but passed.
- **hermes:** avg 63s, range 14–140s.
- **pi:** avg 114s, range 12–300s. Slow on bash-01 and multifile cases.
- **codex:** avg 95s, range 12–301s. bash-01 hit 301s but passed.
- **openhands:** avg 129s, range 28–254s. Slowest working adapter.
- **goose:** avg 105s, range 6–302s. 100% across all 11 cases. js-02 and js-03 at 300s (passed at limit).

### 2026-06-29 observations

aider avg 11s is the standout — this model's MoE architecture (3B active params) makes aider's few-turn edit style extremely fast. interpreter at 100% confirms the model handles tool-use round-trips well. The 3 adapters at 92% all miss bash-01-topwords partially (3/4), likely a pipeline edge case under these adapters' prompting style rather than a model capability limit.

## MLX runtime results (2026-06-12)

hermes via `mlx_lm.server`: **28/28 (100%) on warm cases** — all 7 real coding
cases passed (js-01 4/4, js-02 4/4, js-03 5/5, js-04 3/3, js-05 5/5, js-06 4/4,
ts-01 3/3). Two cold-start failures (bash-01 and smoke) due to mlx_lm.server JIT
compilation not yet complete on the first request after server start — not a model
quality issue. Warm-case timing: 117–301s (avg ~228s), ~2.5× slower than LMS.

## Known issues

**hermes error(1) — all cases (historic):** hermes previously failed on all models;
resolved 2026-06-11 by switching to `backend: local`. Now fully functional.

**codex non-zero exit on js-06, ts-01:** codex exits with rc=1 after successfully applying edits. No data loss — grader scored full points. Likely a codex CLI bug (fails to clean up a subprocess). Monitor across runs.

## Observations across runs

### 2026-06-29 — LMS overnight (run `20260629-235247`)

Full sweep: aider/interpreter/goose 100%. goose js-02 and js-03 at 300s (passed at limit). pi 97% (bash-01 3/4). codex/hermes/openhands 92% — all three miss bash-01-topwords with 3/4 (not 4/4), consistent pattern suggesting a shell pipeline edge case under these adapters' prompting format. caveman confirmed LMS-incompatible. cline/opencode not run.

### 2026-06-12 — MLX (partial)

hermes via mlx_lm.server: 28/28 warm-case 100%. Two cold-start failures (bash-01, smoke) due to MLX JIT not warmed. See MLX section below.

## Status

**keep** — best aider performance in the suite (100%, avg 11s). interpreter also 100%. MoE architecture makes this the fastest model per-token in the benchmark. Needs cline and opencode sweep to complete the adapter picture.

## Comparison within family

qwen3-coder-30b vs qwen3-coder-next (both are Qwen3-Coder family):
- On codex/caveman: near-identical quality, but coder-next is notably faster with caveman
- coder-next has opencode broken (error(1)); coder-30b opencode works at 97.1%
- For production use: prefer coder-30b until opencode compatibility is restored for coder-next
