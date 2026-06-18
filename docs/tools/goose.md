# goose

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | goose (Block Goose) |
| **CLI command** | `goose run` |
| **Version** | 1.38.0 |
| **Adapter script** | [`adapters/goose-lms.sh`](../../adapters/goose-lms.sh) |
| **How it connects** | `GOOSE_PROVIDER=openai` with `OPENAI_BASE_URL` pointing at `LMS_BASE_URL`. Model via `GOOSE_MODEL`. No config file needed — fully env-var driven. |
| **Last reviewed** | 2026-06-18 |

## Edit mechanism

- **Format:** goose uses tool calls via the `developer` builtin extension (`--with-builtin developer`). Tools include `read_file`, `write_file`, `patch_file`, and shell execution. The model emits JSON tool calls; goose executes them and loops.
- **File targeting:** autonomous CWD discovery via file tools.
- **Multi-file edits:** tool-call architecture supports it natively; expected to be reliable on capable models.

## Iteration / self-verify behaviour

goose runs as an autonomous agent loop. `--max-turns 30` caps iterations to prevent hangs. For self-verify cases (js-05, js-06), goose can run the test suite via shell tool and iterate on failures — same strength as cline and opencode.

## Failure modes

**Session state pollution:** goose stores sessions by default; `--no-session` prevents state from leaking between benchmark runs.

**Tool format sensitivity:** goose's `developer` builtin uses its own internal tool schema. If the model produces malformed tool calls, goose will loop until `--max-turns` is hit rather than failing fast.

**Large output truncation:** goose may truncate long tool outputs. Cases with many files or large test output may lose context mid-run.

## Adapter flags and their rationale

| Flag / Env | Reason |
|------------|--------|
| `GOOSE_PROVIDER=openai` | Selects the OpenAI-compatible provider |
| `OPENAI_BASE_URL=$LMS_BASE_URL` | Points at LM Studio instead of api.openai.com |
| `OPENAI_API_KEY=$LMS_API_KEY` | Required by openai provider; any value works with LMS |
| `GOOSE_MODEL=$MODEL_ID` | Selects the model |
| `--with-builtin developer` | Enables file read/write/patch and shell tools |
| `--no-session` | Prevents session state from persisting between runs |
| `--max-turns 30` | Caps the agent loop to avoid infinite-loop hangs |
| `-i -` | Reads prompt from stdin (non-interactive mode) |

## Install

```bash
brew install block/tap/goose
```

## Status

**under-evaluation** — smoke-tested 2026-06-18 (lms runtime). 9/10 cases pass; qwen3.5-9b fails `smoke-01-edit-file` (PARTIAL — reached the model but produced no edit). All larger models pass 100%. Full benchmark with `qwen/qwen3.6-35b-a3b` in progress.

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (36s) | 2/2 (17s) |
| qwen/qwen3.5-9b | 2/2 (15s) | 0/2 (9s) — no edit |
| google/gemma-4-26b-a4b-qat | 2/2 (15s) | 2/2 (35s) |
| qwen/qwen3-coder-30b | 2/2 (10s) | 2/2 (13s) |
| qwen/qwen3-coder-next | 2/2 (32s) | 2/2 (77s) |

Note: `read` tool not available in goose's developer builtin — goose falls back to `shell` + `cat` automatically (observed in logs). Functional workaround, no action needed.
