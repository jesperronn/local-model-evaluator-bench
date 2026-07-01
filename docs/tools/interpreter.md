# interpreter

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% on qwen3.6-35b-a3b (lms) |
| **Speed (avg)** | ~55s per case |
| **Best model** | qwen/qwen3.6-35b-a3b |
| **Recommended for** | autonomous multi-file edits, self-verify loops |
| **Status** | stable |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Open Interpreter |
| **CLI command** | `interpreter` |
| **Version** | latest |
| **Adapter script** | [`adapters/interpreter-lms.sh`](../../adapters/interpreter-lms.sh) |
| **How it connects** | Built-in `lmstudio` provider (hardwired to `localhost:1234/v1`). Model overridden at runtime via `-c 'model="..."'` without touching `config.toml`. |
| **Last reviewed** | 2026-06-30 |

## Edit mechanism

- **Format:** Open Interpreter uses a code-execution loop — the model generates code (Python, shell, etc.) which the runtime executes, then feeds stdout/stderr back for the next turn. File edits happen by writing Python/shell code that modifies files directly.
- **File targeting:** model-driven. The model must write code that targets the correct files in CWD.
- **Multi-file edits:** supported in theory; the model writes separate edit scripts per file. Reliability depends on how well the model plans multi-file edits as code.

## Iteration / self-verify behaviour

Open Interpreter's code-execution loop is inherently iterative — the model sees execution output and can retry. For self-verify cases (js-0ps, js-06), the model can run the test suite as a shell command and iterate on failures. This is a strength of the interpreter architecture.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| qwen/qwen3.6-35b-a3b | 100% | ~55s | 2026-06-18 | ok |
| qwen/t5-small | 0% | 0s | N/A | broken |

## Capability notes

- **tool-editing reliability:** code quality for file edits can be problematic if the model generates incorrect logic for Python/shell writes.
- **bash editing:** no known blockers beyond general sandbox restrictions.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `exec` | Non-interactive execution mode (vs bare `interpreter` which starts the T/UI) |
| `-s workspace-write` | Sandbox: restricts to file writes within CWD only |
| `-c 'model_provider="lmstudio"'` | Selects the built-in LM Studio provider |
| `-c "model=\"$MODEL_ID\""` | Overrides the model at runtime |

## Failure modes

**Sandbox requirement:** the adapter uses `interpreter exec -s workspace-write` to restrict execution to file writes within the workspace. Broader sandboxes (`workspace-write` is the tightest useful scope) prevent accidental side effects. Cases that require running `npm install` or other network operations may fail if the sandbox blocks them.

**Code quality for file edits:** unlike diff-based adapters, Open Interpreter writes code to edit files (e.g. Python `pathlib` writes or shell `sed`). If the model generates correct logic but incorrect file-write code, edits may corrupt the target file rather than fail cleanly.

## Status

**stable** — full 10-case benchmark completed 2026-06-18 (lms runtime, `qwen/qwen3.6-35b-a3b`): 36/36 points (1.00).
