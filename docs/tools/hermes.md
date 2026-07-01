# hermes

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | ~95% across working models |
| **Speed (avg)** | ~97s per case |
| **Best model** | qwen/qwen3.6-35b-a3b |
| **Recommended for** | autonomous multi-file edits, self-verify loops |
| **Status** | stable |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Hermes Agent |
| **CLI command** | `hermes` |
| **Version** | v0.17.0 (2026.6.19) |
| **Adapter script** | [`adapters/hermes-lms.sh`](../../adapters/hermes-lms.sh) |
| **How it connects** | Built-in `lmstudio` provider, configured in `~/.hermes/config.yaml` (`provider: lmstudio`, `base_url: http://127.0.0.1:1234/v1`). Approvals handled by a "smart guardian" LLM running locally. |
| **Last reviewed** | 2026-06-30 |

## Edit mechanism

- **Format:** hermes uses a tool-call based agent loop. With `-t file,terminal` it can read/write files and execute shell commands directly.
- **File targeting:** autonomous CWD discovery via the file toolset.
- **Multi-file edits:** tool-calling architecture handles multi-file cases well. Scores 100% on js-03 and js-04 with capable models.

## Iteration / self-verify behaviour

hermes iterates naturally via its tool-call loop. With `--yolo` (used in bench mode), it proceeds without guardian interruption. Self-verify cases (js-06) pass cleanly — hermes runs tests, observes failures, and re-edits until they pass.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| qwen/qwen3.6-35b-a3b | 100% | measured pending | measured pending | |
| qwen/qwen3.5-9b | 94% | measured pending | measured pending | 2 cases fail |
| devstral-small-2-2512 | 89% | measured pending | measured pending | |
| google/gemma-4-26b-a4b-qat | 100% | measured pending | measured pending | |
| qwen/qwen3.6-27b | 97% | measured pending | measured pending | 1 case fail |
| zai-org/glm-4.7-flash | 37% | measured pending | measured pending | Timeout floor — GGUF too slow |
| qwen/qwen3-coder-30b | 92% | measured pending | measured pending | bash-01 3/4, 2 smoke WARNs |

## Capability notes

- **Multi-file edits:** highly reliable via tool-calling architecture.
- **Bash editing:** supported via terminal toolset; note historical `-t file,terminal` conflict (fixed).
- **Context window:** requires minimum 6rypt 64K context window; aborts if model is smaller.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--provider lmstudio` | Selects the pre-configured LM Studio provider |
| `-m "$MODEL_ID"` | Specifies the model key |
| `-t file,terminal` | Enables file toolset and terminal — conflict fixed in v0.17.0 |
| `--yolo` | Bypasses smart guardian in non-interactive runs; safe in sandboxed bench |
| `-z "$PROMPT"` | Non-interactive prompt delivery |

## Failure modes

**error(1) with correct result (js-03):** hermes exits with rc=1 after correctly editing files and passing the grader on js-03-multifile-cache. The edit is applied; the non-zero exit is a subprocess cleanup artifact. Cosmetic — doesn't affect scores.

**Context window floor:** hermes enforces a hard 64 K minimum context window and aborts in ~3 s if the model is loaded smaller. This was the original root cause of systematic failures before `BENCH_CONTEXT=65536` was established in `config.sh`.

**Historical — tool-name conflict (`-t file,terminal`):** combining both toolsets caused hermes to drop the file tools entirely, leaving only a process tool and preventing any file edits. Fixed by using `-t file` only.

**Historical — guardian blocking:** the original adapter used `approvals.mode: smart` without `--yolo`, causing the guardian LLM to deny or delay file-write tool calls. Fixed by adding `--yolo` for non-interactive (bench) runs.

## Status

**stable** — 2026-06-29 overnight sweep confirms strong performance across all models except glm-4.7-flash (GGUF too slow, timeout floor).

### Full benchmark results (2026-06-18, lms, run `20260618-213005`)

| Case | Score | Time | Status |
|------|-------|------|--------|
| bash-01-topwords | 4/4 | 118s | ok |
| js-01-slugify-bug | 4/4 | 63s | ok |
| js-02-debounce-feature | 4/4 | 86s | ok |
| js-03-multifile-cache | 5/5 | 93s | error(1)† |
| js-04-multifile-rename | 3/int | 41s | ok |
| js-05-multiselect-filter | 5/5 | 183s | ok |
| js-06-lint-and-test | — | — | pending |
| smoke-00-hello | — | — | pending |
| smoke-01-edit-file | — | — | pending |
| ts-01-groupby | — | — | pending |

† Cosmetic exit-code artifact; all assertions pass.

_Pending rows to be filled once the resumed run completes._
