# copilot (GitHub Copilot CLI)

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending (full suite blocked until 2026-08-29; see Failure modes) |
| **Speed (avg)** | measured pending |
| **Best model** | measured pending |
| **Recommended for** | measured pending |
| **Status** | experimental |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | GitHub Copilot CLI |
| **CLI command** | `copilot` |
| **Version** | measured pending |
| **Adapter script** | [`adapters/copilot.sh`](../../adapters/copilot.sh) |
| **How it connects** | `COPILOT_PROVIDER_BASE_URL` redirected at the LiteLLM proxy's OpenAI-compatible endpoint (`COPILOT_PROVIDER_TYPE=openai`), bypassing GitHub's Copilot service entirely; `COPILOT_OFFLINE=true` stops it phoning home. `COPILOT_PROVIDER_MODEL_ID=gpt-4o` is a well-known catalog entry copilot uses only to size token limits/agent config — the real model sent on the wire is `COPILOT_PROVIDER_WIRE_MODEL`, prefixed by runtime (`omlx/<id>`, `lms/<id>`, ...). |
| **Runtime model discovery** | **no** — the wire model id is set explicitly from `$MODEL_ID`/`--provider`; no catalog query against the local backend. |
| **Last reviewed** | 2026-08-29 |

## Edit mechanism

Not yet evaluated in this bench.

## Iteration / self-verify behaviour

Not yet evaluated in this bench.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|

No clean full-suite run recorded yet (blocked by the bugs below until 2026-08-29; smoke-verified 3/3 after fixing them — see [omlx--ornith-1.5-35b-a3b-mlx-4bit.md](../models/omlx--ornith-1.5-35b-a3b-mlx-4bit.md)).

## Capability notes

Not yet evaluated — no known blockers documented beyond the fixed issues below.

## Adapter flags and their rationale

| Flag / env var | Reason |
|------|--------|
| `COPILOT_PROVIDER_BASE_URL=$LITELLM_BASE_URL` | Routes all model calls through the local litellm proxy instead of GitHub's Copilot backend. |
| `COPILOT_PROVIDER_TYPE=openai` | Tells copilot to treat the endpoint as a generic OpenAI-compatible provider. |
| `COPILOT_PROVIDER_MODEL_ID=gpt-4o` | A catalog entry copilot needs to resolve token-limit/sizing defaults; not the model actually called. |
| `COPILOT_PROVIDER_WIRE_MODEL=$PREFIXED_MODEL_ID` | The real runtime-prefixed model id sent on the wire. |
| `COPILOT_OFFLINE=true` | Prevents any call back to GitHub's own service. |
| `--allow-all-tools --allow-all-paths --no-ask-user -p "$(cat)"` (non-interactive only) | Runs unattended in the sandbox with the piped prompt. |

## Failure modes

**`PROVIDER` ignored `--runtime` (fixed 2026-08-29):** `copilot.sh` unconditionally defaulted `PROVIDER` to `lms`, missing the `${RUNTIME:-lms}` fallback present in `aider.sh`/`claude.sh`/`goose.sh`/`omp.sh` — so `--runtime omlx` (and every other non-`lms` runtime) silently routed to LM Studio instead.

**Copilot's `apply_patch` tool crashes the proxy on non-`lms` backends (fixed 2026-08-29):** Copilot CLI always advertises its built-in `apply_patch` tool as `{"type": "custom", "custom": {...freeform grammar...}}` — an OpenAI *Responses API* tool shape, not a Chat Completions `function` tool. None of the local runtimes' OpenAI-compatible chat/completions endpoints implement custom/freeform tools; forwarding it made the backend call return `None` instead of a stream, which litellm-proxy's own streaming-iterator hook chain then crashed on with `TypeError: 'async for' requires an object with __aiter__ method, got NoneType` (confirmed by capturing copilot's real request body via a local HTTP relay and replaying it directly against the proxy — the crash reproduces with a bare `curl` once the `apply_patch` tool entry is included, and disappears once it's stripped). Fixed with a litellm pre-call hook — [`config-templates/litellm-hooks/strip_unsupported_tools.py`](../../config-templates/litellm-hooks/strip_unsupported_tools.py) — that drops any tool whose `type` isn't `function` before the request reaches the backend, mounted into the proxy container by `bin/litellm-proxy` and registered via `litellm_settings.callbacks` in `config-templates/litellm.yaml`. This affects every runtime routed through the litellm proxy, not just omlx.

## Status

**experimental** — both blocking bugs above are fixed and smoke-verified (3/3 on `Ornith-1.5-35B-A3B-MLX-4bit`/omlx); a clean full-suite accuracy run is still pending.
