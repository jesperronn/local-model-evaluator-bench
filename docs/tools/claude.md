# claude (Claude Code CLI)

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best model** | measured pending |
| **Recommended for** | measured pending |
| **Status** | experimental |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Claude Code CLI |
| **CLI command** | `claude` |
| **Version** | measured pending |
| **Adapter script** | [`adapters/claude-lms.sh`](../../adapters/claude-lms.sh), [`adapters/claude-omlx.sh`](../../adapters/claude-omlx.sh) |
| **How it connects** | `ANTHROPIC_BASE_URL` pointed at the local server (stripped of a trailing `/v1`, since Claude Code's Stainless SDK appends `/v1/messages` itself); `ANTHROPIC_MODEL` / `ANTHROPIC_DEFAULT_{SONNET,HAIKU,OPUS}_MODEL` all pinned to `$MODEL_ID` so internal sub-task routing can't fall back to the real Anthropic API. |
| **Runtime model discovery** | **no** — every model-tier env var is set explicitly to `$MODEL_ID` on each run (`adapters/claude-lms.sh`/`claude-omlx.sh`); no call to a `/v1/models`-equivalent endpoint is made by the adapter. |
| **Last reviewed** | 2026-08-09 |

## Edit mechanism

- **Format:** not yet evaluated in this bench.
- **File targeting:** not yet evaluated in this bench.
- **Multi-file edits:** not yet evaluated in this bench.

## Iteration / self-verify behaviour

Not yet evaluated in this bench.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|

No runs recorded yet.

## Capability notes

Not yet evaluated — no known blockers documented.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `ANTHROPIC_BASE_URL="${LMS_BASE_URL%/v1}"` / `"${OMLX_BASE_URL%/v1}"` | Claude Code's SDK appends `/v1/messages` itself; passing the URL with `/v1` already on it would double it up. |
| `ANTHROPIC_MODEL` + `ANTHROPIC_DEFAULT_{SONNET,HAIKU,OPUS}_MODEL` all set to `$MODEL_ID` | Prevents Claude Code's internal tool-selection routing from calling the real Anthropic API for a sub-task tier that wasn't explicitly overridden. |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` | Suppresses feature flags the local OpenAI-compatible server may not implement. |
| `--allow-dangerously-skip-permissions` (non-interactive only) | Runs unattended in the sandbox; only set when stdin is piped. |

## Failure modes

Not yet evaluated in this bench.

## Status

**experimental** — adapters exist for both lms and omlx backends but no benchmark runs are recorded yet.
