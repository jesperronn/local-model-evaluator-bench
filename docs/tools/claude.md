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

**Stalls on slower local models (root-caused 2026-08-29, not a wiring bug):** on `Ornith-1.5-35B-A3B-MLX-4bit`/omlx, most trials hit `status=stall` at almost exactly the bench's default `--stall 120` ceiling. Isolated re-runs with `--stall 200` and no concurrent load passed cleanly (4/4 on `js-01-slugify-bug` in 59s), while harder/longer-context cases (`bash-01-topwords`, `deleg-01-validate-format-pipeline`, `ts-01-groupby`) still needed the full 200s budget. Claude Code's system prompt is heavier than other harnesses tested here (goose, omp), so on a slow local backend its per-turn latency crosses the default stall window sooner as task complexity/context grows. When benchmarking claude against a large or slow local model, raise `--stall` (200+) for a representative score — the default 120s is tuned for faster models/adapters.

## Status

**experimental** — adapters exist for both lms and omlx backends. On `Ornith-1.5-35B-A3B-MLX-4bit`/omlx specifically, use `--stall 200` or higher (see Failure modes above).
