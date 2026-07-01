# qwen/qwen3-coder-next

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | ~94% (154/164) |
| **Speed (avg)** | ~40s (opencode is fastest) |
| **Best adapter** | codex, hermes, opencode — 100% accuracy |
| **Recommended for** | general agentic coding, multi-file edits |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3-coder-next` |
| **Family / arch** | Qwen3-Coder, MoE (512 micro-experts, 10 active/token) |
| **Parameter count** | ~86B total, ~6.5B active |
| **Disk size** | 60.31 GiB (as reported by `lms load`, 2026-06-09) |
| **Added** | 2026-06-09 |
| **Last run** | 2026-06-13 |
| **Doc updated** | 2026-06-13 |

## Results summary

Excellent coding model. All 5 adapters work at high scores: codex, hermes, and opencode all at 100%, caveman 96.7%, aider 71.9%. Overall 154/164 (93.9%). On par with qwen3-coder-30b except aider trails slightly. hermes and opencode were both broken in the initial run (2026-06-09) but were fixed when hermes switched to `backend: local`. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Adapter-specific — aider, bash-01-topwords (0/4):** aider fails the bash CLI case across all runs while codex, hermes, and caveman score 4/4. The model produces a valid solution but aider's diff format isn't applied correctly.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails this multi-file rename case while codex, hermes, and caveman pass 3/3. Aider's file-targeting requires explicit `--file` hints; the model edits only one of the two files.

**Soft failure — aider, js-03-multifile-cache (1/5):** aider scores 1/5; caveman (0/1) also fails. codex, hermes, opencode pass 5/5. The case requires atomic edits across ≥2 files.

**Adapter-specific — caveman, js-03-multifile-cache (0/1):** caveman fails this multi-file case (0/1) while codex, hermes, and opencode pass 5/5.

## Timing observations

- **codex:** 45–263s. js-03-multifile-cache 263s (longest). All ok.
- **caveman:** 22–70s. Consistently faster than codex.
- **aider:** 10–52s. Fastest adapter.
- **hermes:** ~38s avg (LMS). Clean on all 9 cases.
- **opencode:** ~35s avg (LMS). Clean on all 9 cases.

## MLX runtime — hermes regression (2026-06-13)

MLX hermes (via `bin/mlx-serve-qwen3-next`) scores significantly lower than LMS hermes
despite tool calls now parsing correctly. LMS hermes: 34/34 100%, 38s avg. MLX hermes:
~0-2/4 per case, 150-285s avg (partial/full failures on bash-01, js-01, js-02 confirmed).

Root cause: The `qwen3_coder` XML tool format (required to fix the `json_tools` parser bug)
presents tools differently from LM Studio's format. The model's response quality degrades
when tools are presented in XML format vs the OpenAI JSON format LMS uses internally.
Specifically:
- `bash-01`: model confused about `process` tool's `session_id` (tries to use it without
  first starting a process, gets "session_id is required" error, gives up)
- `js-01/02`: model generates responses but misses tests
- MLX timing is 4–7× slower per case vs LMS

**Conclusion:** MLX hermes is not useful for this model in the current configuration.
The model works correctly on LMS (LM Studio's native tool format). MLX hermes is a known
regression until either the model's tool format expectation is aligned with qwen3_coder
or LMS-style tool presentation can be reproduced on the MLX server.

## Known issues

No current blockers for LMS adapter. hermes and opencode were fixed 2026-06-11 when hermes
switched to `backend: local`. opencode was likely fixed as a side-effect of the same fix.

See "MLX runtime" section above for MLX hermes regression.

## Better alternatives

No strictly-better model is currently recommended for this specific workload based on current evaluation.

## Status

**keep** — comprehensive, well-tested across all 5 adapters. The aider gap is a known format issue consistent across all models.

## Comparison within family

Compared to qwen3-coder-30b on all adapters:
- codex, hermes, opencode: identical (100% both)
- caveman: 96.7% vs 100% (coder-next misses js-03)
- aider: 71.9% vs 81.2% (slight regression)
- caveman is noticeably faster on coder-next (22–70s vs 46–127s)
