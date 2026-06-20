# interpreter

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Open Interpreter |
| **CLI command** | `interpreter` |
| **Version** | latest |
| **Adapter script** | [`adapters/interpreter-lms.sh`](../../adapters/interpreter-lms.sh) |
| **How it connects** | Built-in `lmstudio` provider (hardwired to `localhost:1234/v1`). Model overridden at runtime via `-c 'model="..."'` without touching `config.toml`. |
| **Last reviewed** | 2026-06-18 |

## Edit mechanism

- **Format:** Open Interpreter uses a code-execution loop — the model generates code (Python, shell, etc.) which the runtime executes, then feeds stdout/stderr back for the next turn. File edits happen by writing Python/shell code that modifies files directly.
- **File targeting:** model-driven. The model must write code that targets the correct files in CWD.
- **Multi-file edits:** supported in theory; the model writes separate edit scripts per file. Reliability depends on how well the model plans multi-file edits as code.

## Iteration / self-verify behaviour

Open Interpreter's code-execution loop is inherently iterative — the model sees execution output and can retry. For self-verify cases (js-05, js-06), the model can run the test suite as a shell command and iterate on failures. This is a strength of the interpreter architecture.

## Failure modes

**Sandbox requirement:** the adapter uses `interpreter exec -s workspace-write` to restrict execution to file writes within the workspace. Broader sandboxes (`workspace-write` is the tightest useful scope) prevent accidental side effects. Cases that require running `npm install` or other network operations may fail if the sandbox blocks them.

**Code quality for file edits:** unlike diff-based adapters, Open Interpreter writes code to edit files (e.g. Python `pathlib` writes or shell `sed`). If the model generates correct logic but incorrect file-write code, edits may corrupt the target file rather than fail cleanly.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `exec` | Non-interactive execution mode (vs bare `interpreter` which starts the TUI) |
| `-s workspace-write` | Sandbox: restricts to file writes within CWD only |
| `-c 'model_provider="lmstudio"'` | Selects the built-in LM Studio provider |
| `-c "model=\"$MODEL_ID\""` | Overrides the model at runtime |

## Known issues

**Code quality for file edits:** unlike diff-based adapters, Open Interpreter writes code to edit files (e.g. Python `pathlib` writes or shell `sed`). If the model generates correct logic but incorrect file-write code, edits may corrupt the target file rather than fail cleanly.

## Test suite inclusion

**Excluded from `DEFAULT_ADAPTERS` and routine smoke runs.**

Open Interpreter has significant cold-start overhead: Python/OI initialisation adds 15–30 s to every run before the model even sees the prompt. This makes it slow as a default in the smoke suite (where speed of diagnosis matters) and inflates wall-clock time in full bench runs. To include it in a run, pass it explicitly:

```sh
bin/smoke --adapter interpreter
bin/bench --adapter interpreter
```

The adapter itself is fully functional — see the benchmark results below.

## Status

**stable** — full 10-case benchmark completed 2026-06-18 (lms runtime, `qwen/qwen3.6-35b-a3b`): 36/36 points (1.00).

### Full benchmark results (2026-06-18, lms, run `20260618-190652`)

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| bash-01-topwords | 4/4 (1.00) | 160s | ok |
| js-01-slugify-bug | 4/4 (1.00) | 64s | ok |
| js-02-debounce-feature | 4/4 (1.00) | 50s | ok |
| js-03-multifile-cache | 5/5 (1.00) | 84s | ok |
| js-04-multifile-rename | 3/3 (1.00) | 72s | ok |
| js-05-multiselect-filter | 5/5 (1.00) | 129s | ok |
| js-06-lint-and-test | 4/4 (1.00) | 115s | ok |
| smoke-00-hello | 2/2 (1.00) | 17s | ok |
| smoke-01-edit-file | 2/2 (1.00) | 17s | ok |
| ts-01-groupby | 3/3 (1.00) | 29s | ok |
| **Total** | **36/36 (1.00)** | | |

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (29s) | 2/2 (18s) |
| qwen/qwen3.5-9b | 2/2 (18s) | 2/2 (12s) |
| google/gemma-4-26b-a4b-qat | 2/2 (11s) | 2/2 (19s) |
| qwen/qwen3-coder-30b | 2/2 (8s) | 2/2 (14s) |
| qwen/qwen3-coder-next | 2/2 (21s) | 2/2 (17s) |
