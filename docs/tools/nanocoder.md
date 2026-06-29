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

### Full sweep (nightly, all 7 models)

Pending. 77 combos queued to run after overnight bench completes.

## Known issues

None discovered yet. Adapter is new — first full sweep pending.

## Status

**smoke-validated** — all 3 smoke cases pass on gemma-4-e4b. Full bench sweep against all 7 models pending (77 combos queued).
