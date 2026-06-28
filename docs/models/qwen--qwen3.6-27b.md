# qwen/qwen3.6-27b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.6-27b` |
| **Family / arch** | Qwen 3.6, dense, 27B |
| **Runtime variants** | MLX-6bit (removed 2026-06-12), **lms GGUF (added 2026-06-28)** |
| **Parameter count** | 27B |
| **Context window** | 128K tokens |
| **License** | <!-- TODO — verify from HuggingFace card --> |
| **Disk size (lms GGUF)** | <!-- TODO — check after loading in LM Studio --> |
| **Disk size (mlx)** | ~21 GB (removed) |
| **Doc updated** | 2026-06-28 |

## Results summary

35.7% overall at 253s average — poor on both dimensions. Only aider was tested at
removal time (partial run); hermes had not yet started. The result was conclusive
enough to remove without completing the sweep. See [LEADERBOARD.md](../../LEADERBOARD.md).

## Failure patterns

**Thinking token leakage into aider edits:** aider uses `whole edit format` and
writes the model's full response (including `<think>` reasoning tokens) directly
into the edited file. The resulting files contain prose mixed into code, producing
syntax errors. Qwen 3.6 models have thinking mode enabled by default.

**Extreme slowness:** 253s average per case — roughly 5× slower than
`qwen3.6-35b-a3b` (48s). Dense 27B architecture with MLX-6bit quantisation
generates tokens significantly slower than the MoE alternative despite having
fewer total parameters on paper.

**Only 1 case passed:** `js-01-slugify-bug` (4/4 in 239s). Every other attempted
case either timed out at 300s or produced bad output due to thinking leakage.

## Status

**Removed 2026-06-12** — dropped from `models.txt`, `models-mlx.txt`, and
`models-aliases.conf` after a single partial run. The model is strictly dominated
by `qwen/qwen3.6-35b-a3b` on every dimension:

| | qwen3.6-27b (dense) | qwen3.6-35b-a3b (MoE) |
|---|---|---|
| Pass% | 35.7% | 94% |
| Avg seconds | 253s | 48s |
| Active params | 27B | 3.6B |
| Thinking leakage | yes (aider broken) | handled correctly |

**Do not revisit.** The MoE variant is faster, far more accurate, uses fewer active
parameters, and handles thinking tokens correctly across all adapters. There is no
scenario where the dense 27B is preferable.

**Better alternative:** `qwen/qwen3.6-35b-a3b` (MoE, 3.6B active).
