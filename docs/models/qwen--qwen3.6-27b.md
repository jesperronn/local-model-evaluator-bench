# qwen/qwen3.6-27b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.6-27b` |
| **Family / arch** | Qwen 3.6, dense, 27B |
| **Runtime variants** | MLX-6bit (removed 2026-06-12), **LMS GGUF (re-added 2026-06-28)** |
| **Parameter count** | 27B |
| **Context window** | 128K tokens |
| **Disk size (lms GGUF)** | ~18 GB |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-29 (run `20260629-134104`) |
| **Doc updated** | 2026-06-30 |

## Results summary

Strong performance on LMS GGUF. On the 2026-06-29 overnight run: codex, goose, and interpreter all scored **38/38 (100%)**; hermes 33/34 (97%); cline 28/34 (82%); aider 26/34 (76%). 5 adapters were not run (skipped or compat-excluded). Overall 201/216 (93%) across 6 tested adapters.

| Adapter | 2026-06-29 (LMS) | Notes |
|---------|-----------------|-------|
| codex | 38/38 (100%) | |
| goose | 38/38 (100%) | |
| interpreter | 38/38 (100%) | |
| hermes | 33/34 (97%) | 1 case fail |
| cline | 28/34 (82%) | Some timeouts on slower cases |
| aider | 26/34 (76%) | Thinking token leakage on some cases |
| caveman | not run | — |
| copilot | not run | — |
| opencode | not run | — |
| openhands | not run | — |
| pi | not run | — |

## Failure patterns

**aider thinking token leakage:** Qwen 3.6 models have thinking mode enabled by default. aider's whole-file edit format writes the full model response (including `<think>` tokens) into the file, producing syntax errors. This was the primary failure mode in the 2026-06-12 MLX run and persists on LMS GGUF, but now affects only a subset of cases (26/34 pass, vs 4/28 pass on MLX).

**cline timeouts:** Dense 27B generates tokens slower than MoE models of comparable capability. cline's multi-turn agent loop amplifies this — some cases exceed the 300s timeout.

## Timing observations

Dense 27B GGUF is noticeably slower than MoE models (qwen3.6-35b-a3b with 3B active params generates ~3–5× faster). Expect 60–200s per case for simple adapters; aider and cline can push to 300s on complex cases (bash-01-topwords).

## History

**2026-06-12 MLX removal:** The model was removed in its MLX-6bit variant after a catastrophic result: 35.7% pass rate at 253s average. Root causes were (1) thinking token leakage into aider edits and (2) extreme slowness vs the MoE alternative. Only aider was tested at removal time.

**2026-06-28 LMS GGUF re-add:** Model re-added for a full sweep using GGUF backend on LMS. The LMS GGUF backend generates faster than MLX-6bit for this dense architecture; timeout failures from 2026-06-12 are reduced but not eliminated.

## Status

**keep (watch)** — 93% across 6 tested adapters is solid for a dense 27B. codex, goose, and interpreter hit 100%. The aider leakage issue persists and the adapter sweep is incomplete (5 adapters not yet run). Consider adding opencode and pi to a follow-up run to complete the picture.

**Better for throughput:** `qwen/qwen3.6-35b-a3b` (MoE, 3B active — faster generation, 100% across all working adapters).
