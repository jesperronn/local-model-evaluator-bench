# openhands

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | openhands |
| **CLI command** | `python -m openhands.core.main` (via adapter wrapper) |
| **Version** | see `pip show openhands-ai` |
| **Adapter script** | [`adapters/openhands-lms.sh`](../../adapters/openhands-lms.sh) |
| **How it connects** | OpenAI-compatible endpoint; model addressed as `openai/<MODEL_ID>` |
| **Last reviewed** | 2026-06-30 |

## How it connects

openhands uses an OpenAI-compatible provider configuration pointing to LM Studio's endpoint. The adapter sets `LLM_API_KEY` and `LLM_BASE_URL` environment variables, and provides the model as `openai/<MODEL_ID>`.

## Edit mechanism

openhands uses a structured agent loop with tool calls for file operations (read, write, patch). It can apply targeted edits, run tests, and iterate based on test output — full self-verify capability.

## Iteration / self-verify behaviour

openhands iterates autonomously — it reads files, applies edits, runs tests via bash tool, and continues until it succeeds or exhausts its iteration budget. The self-verify loop is one of its key strengths.

## Benchmark results (2026-06-29, lms, run `20260629-*`)

| Model | Score | Notes |
|-------|-------|-------|
| qwen/qwen3.6-35b-a3b | 38/38 (100%) | |
| qwen/qwen3.5-9b | 33/38 (86%) | |
| devstral-small-2-2512 | 12/32 (37%) | Stalls/errors — model protocol issue |
| google/gemma-4-26b-a4b-qat | 30/36 (83%) | |
| qwen/qwen3.6-27b | not run | — |
| zai-org/glm-4.7-flash | 12/32 (37%) | Timeout floor |
| qwen/qwen3-coder-30b | 35/38 (92%) | bash-01 WARN, js-03 stall |

openhands scores **100% on qwen3.6-35b-a3b**, the primary model. The devstral collapse (37%) is a model-specific failure — the model appears to not complete tasks under openhands' protocol, likely a tool-call schema mismatch.

## Known issues

**devstral incompatibility:** openhands and opencode both collapse to 37% on devstral-small-2-2512 — same pattern as LMS-incompatible caveman/copilot. This is not an openhands bug; it's a model-side issue where devstral doesn't produce openhands-compatible tool calls.

**glm-4.7-flash GGUF:** timeout floor at 37% — GGUF backend too slow for 300s timeout.

## Status

**stable** — 100% on the primary model (qwen3.6-35b-a3b), 83–92% on other capable models. Strong self-verify capabilities. Avoid with devstral and glm-4.7-flash.
