# qwen/qwen3.6-35b-a3b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.6-35b-a3b` |
| **Family / arch** | Qwen3.6, MoE (35B total, 3B active) |
| **Parameter count** | 35B total, 3B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-08 |
| **LMS entry removed** | 2026-06-10 |

## Results summary

The strongest general model in the suite. opencode, codex, and caveman all score 100%. aider scores 66.7% due to consistent multi-file and self-verify failures — a pattern that repeats across large Qwen3 MoE models with aider. Despite 35B total params, the 3B active architecture keeps it fast. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Adapter-specific — aider, js-03-multifile-cache (0/5):** aider scores 0/5 while all other adapters score 5/5. The model likely produces valid content but aider's edit format fails to apply both file changes atomically. No explicit `--file` hints are passed.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails the multi-file rename case; all other adapters pass 3/3. Same mechanism: second file not updated, ESM import broken.

**Adapter-specific — aider, js-06-lint-and-test (0/4):** aider scores 0/4 on the self-verify lint case while all other adapters score 4/4. The model does not iterate through lint failures under aider, possibly because aider doesn't feed test output back in a format the model acts on.

All three failures are aider-specific and do not appear on opencode, codex, or caveman. This is strong evidence of an aider format/prompt interaction, not a model capability gap.

## Timing observations

- **aider:** 38–130s. bash-01-topwords took 130s (slow for a 3B-active model; likely the model iterated on the shell pipeline).
- **opencode:** 45–93s. Consistent across cases.
- **codex:** 19–74s. Fastest of the non-aider adapters for this model.
- **caveman:** 24–69s. Similar to codex.

## Known issues

**hermes error(1) — all cases:** adapter-level issue, not model-specific.

## Status

**model: active** — perfect scores on three adapters; top-ranked model in the suite. Still benchmarked via Ollama as `qwen3.6:35b-a3b-coding-mxfp8` (MLX/mxfp8).

**LMS entry removed 2026-06-10** — `qwen/qwen3.6-35b-a3b` (GGUF) dropped from `models.txt` for two reasons: (1) the identical model already runs via Ollama in MLX format, making the GGUF entry redundant; (2) moving to an all-MLX LMS runtime for consistency. Replaced in `models.txt` by `qwen/qwen3.6-27b` (MLX-6bit, already downloaded), which covers the same model family at 27B dense instead of 35B MoE.

## Comparison within family

qwen3.6-35b-a3b vs qwen3-coder-30b:
- qwen3.6-35b-a3b achieves 100% on opencode/codex/caveman; qwen3-coder-30b is 97.1%/100%/100%
- The 35b-a3b is a general model; coder-30b is fine-tuned for code — for code tasks, both are near-identical
- For non-code tasks, 35b-a3b is likely stronger
