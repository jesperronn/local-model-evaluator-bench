# nanocoder

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | nanocoder |
| **CLI command** | `nanocoder` |
| **Version** | 1.28.1 |
| **Adapter script** | [`adapters/nanocoder-lms.sh`](../../adapters/nanocoder-lms.sh) |
| **How it connects** | LM Studio via `NANOCODER_PROVIDERS` env var (JSON array); no config file needed |
| **Last reviewed** | 2026-06-30 |
| **Smoke test** | 2026-06-30 — **3/3 PASS** on gemma-4-e4b |

## Install

```bash
npm install -g nanocoder
nanocoder --version   # expect 1.28.1+
```

## How it connects

nanocoder supports LM Studio natively as a provider. The adapter injects a provider JSON via the `NANOCODER_PROVIDERS` environment variable — no config file is written to disk, making bench runs self-contained and parallel-safe.

```bash
NANOCODER_PROVIDERS='[{"name":"LM Studio","baseUrl":"http://localhost:1234/v1","models":["qwen/qwen3.6-35b-a3b"],"contextWindow":65536}]' \
NANOCODER_TRUST_DIRECTORY=1 \
nanocoder run --provider "LM Studio" --model "qwen/qwen3.6-35b-a3b" "fix the bug in app.js"
```

`NANOCODER_TRUST_DIRECTORY=1` bypasses the interactive approval prompt for file edits — required for non-interactive bench runs.

## Edit mechanism

nanocoder uses a structured tool-call interface. It reads files, reasons about changes, and emits targeted edits via a tool-call API rather than whole-file rewrites. Supports multi-file edits natively.

## Iteration / self-verify behaviour

nanocoder can iterate: it runs tools (read, write, execute), observes results, and continues until it considers the task done or hits a natural stopping point. For self-verify cases (js-05, js-06), it can run the test suite and fix failures.

## Non-interactive mode

When stdin is not a terminal, the adapter calls `nanocoder run --provider ... --model ... "<prompt>"`. The prompt is prefixed with the working directory to give the model filesystem context.

## Benchmark results

### Smoke (2026-06-30, run `20260630-012119`, model `google/gemma-4-e4b`)

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| smoke-00-hello | 2/2 | 12s | PASS |
| smoke-01-edit-file | 2/2 | 42s | PASS |
| smoke-02-numbers | 2/2 | 36s | PASS |
| **Total** | **6/6 (100%)** | | |

All 3 smoke cases pass on gemma-4-e4b. The adapter connection is stable; NANOCODER_PROVIDERS injection works. Full sweep against all 7 models scheduled after smoke validation.

### Full sweep (nightly, 2026-06-30, run `20260630-014836+`)

| Model | Score | Notes |
|-------|-------|-------|
| qwen/qwen3.6-35b-a3b | 35/36 (97%) | js-04-multifile-rename 0/1 (import not updated); js-05 5/5 via write+read only |
| qwen/qwen3.5-9b | 24/34 (71%) | XML tool call fallback — smoke-01/02, ts-01, js-05 all fail with error(1) |
| mistralai/devstral-small-2-2512 | 33/38 (87%) | bash-01 1/4 (execute_bash blocked); smoke-01 0/2; js-01–06 all PASS |
| google/gemma-4-26b-a4b-qat | 36/38 (95%) | js-01 2/4; all other cases PASS |
| qwen/qwen3.6-27b | 34/38 (89%) | bash-01 0/4 (execute_bash blocked); all JS cases PASS |
| zai-org/glm-4.7-flash | 12/34 (35%) | All cases 300s timeout — GGUF too slow for multi-turn tool calls |
| qwen/qwen3-coder-30b | 36/38 (95%) | Only smoke-01 fails; bash-01 PASS 4/4 — only model to pass bash case |

## Known issues

**XML tool call fallback (model-dependent):** some models (qwen3.5-9b) emit XML-style tool calls (`<tool_call><function=string_replace>…</function>`) instead of OpenAI-format structured JSON tool calls. nanocoder only processes structured tool calls — XML calls are silently ignored ("Model returned an empty response with no tool calls"). Affected cases fail quickly (6–16s) with error(1). gemma-4-e4b and qwen3.6-35b-a3b produce proper structured calls and score well; qwen3.5-9b does not.

**js-04-multifile-rename (qwen3.6-35b-a3b):** nanocoder edited the export in `temperature.js` but failed to update the import in the consuming file, leaving the code in a broken state. Other adapters (aider, interpreter) pass this case on the same model. Likely nanocoder's context window or file-discovery heuristics didn't include the consumer file.

## Status

**production-ready** — full sweep across all 7 models complete. Best results on qwen3-coder-30b (95%), gemma-4-26b-a4b-qat (95%), and qwen3.6-35b-a3b (97%). Avoid on glm-4.7-flash (GGUF too slow). qwen3.5-9b has XML tool-call issues (71%).
