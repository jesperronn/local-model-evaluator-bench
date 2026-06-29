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
| **Smoke test** | 2026-06-30 (in progress) |

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

| Model | Run | Results |
|-------|-----|---------|
| google/gemma-4-e4b | 20260630-012119 smoke | TBD — in progress |
| all 7 models | nightly sweep | pending after smoke validation |

Smoke test on gemma-4-e4b in progress (2026-06-30 01:21). Full model sweep will follow if smoke passes.

## Known issues

None discovered yet. Adapter is new — first bench run in progress.

## Status

**under-evaluation** — adapter written and smoke-testing. Full bench sweep against all 7 models pending smoke result.
