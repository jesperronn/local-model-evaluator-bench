# pi

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | pi (coding agent) |
| **CLI command** | `pi` |
| **npm package** | `@earendil-works/pi-coding-agent` |
| **Version** | latest |
| **Adapter script** | [`adapters/pi-lms.sh`](../../adapters/pi-lms.sh) |
| **How it connects** | `--provider lmstudio` selects the built-in LM Studio provider (localhost:1234/v1). Model passed via `--model`. |
| **Last reviewed** | 2026-06-18 |

## Edit mechanism

- **Format:** pi uses an agentic coding loop with tool calls. The `-p` flag runs it headlessly with a prompt string; without `-p` it starts an interactive TUI.
- **File targeting:** autonomous — pi discovers and edits files in CWD via its own toolset.
- **Multi-file edits:** tool-call architecture supports multi-file edits natively.

## Iteration / self-verify behaviour

pi is an autonomous agent loop. For self-verify cases (js-05, js-06), pi can run tests and iterate on failures. The `-p` flag feeds the full prompt non-interactively; the loop runs until the task is complete or a turn limit is hit.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--provider lmstudio` | Selects LM Studio as the model backend |
| `--model "$MODEL_ID"` | Overrides the model at runtime |
| `-p "$(cat)"` | Non-interactive prompt delivery (headless mode) |

## Known issues

**Caveman shares the pi runtime:** `caveman` is also built on the pi agent runtime. If both are run concurrently in `bin/bench`, they share the same `~/.pi/agent/models.json` config. Verify they use separate config paths or run them in separate slots.

## Status

**stable** — full 10-case benchmark completed 2026-06-18 (lms runtime, `qwen/qwen3.6-35b-a3b`): 36/36 points (1.00). Consistently fast — fastest agent in the field on most cases.

### Full benchmark results (2026-06-18, lms, run `20260618-190652`)

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| bash-01-topwords | 4/4 (1.00) | 49s | ok |
| js-01-slugify-bug | 4/4 (1.00) | 18s | ok |
| js-02-debounce-feature | 4/4 (1.00) | 19s | ok |
| js-03-multifile-cache | 5/5 (1.00) | 35s | ok |
| js-04-multifile-rename | 3/3 (1.00) | 26s | ok |
| js-05-multiselect-filter | 5/5 (1.00) | 55s | ok |
| js-06-lint-and-test | 4/4 (1.00) | 68s | ok |
| smoke-00-hello | 2/2 (1.00) | 8s | ok |
| smoke-01-edit-file | 2/2 (1.00) | 6s | ok |
| ts-01-groupby | 3/3 (1.00) | 19s | ok |
| **Total** | **36/36 (1.00)** | | |

### Full benchmark results (2026-06-18, lms, run `20260618-215910`) — `google/gemma-4-26b-a4b-qat`

Run concurrently with a hermes bench on the same model; timeouts reflect slot contention, not correctness failures — all cases passed.

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| bash-01-topwords | 4/4 (1.00) | 300s | timeout† |
| js-01-slugify-bug | 4/4 (1.00) | 129s | ok |
| js-02-debounce-feature | 4/4 (1.00) | 180s | ok |
| js-03-multifile-cache | 5/5 (1.00) | 187s | ok |
| js-04-multifile-rename | 3/3 (1.00) | 79s | ok |
| js-05-multiselect-filter | 5/5 (1.00) | 200s | ok |
| js-06-lint-and-test | 4/4 (1.00) | 300s | timeout† |
| smoke-00-hello | 2/2 (1.00) | 38s | ok |
| smoke-01-edit-file | 2/2 (1.00) | 27s | ok |
| smoke-02-numbers | 2/2 (1.00) | 39s | ok |
| ts-01-groupby | 3/3 (1.00) | 300s | timeout† |
| **Total** | **38/38 (1.00)** | | |

† Completed within the timeout window (all assertions pass); 300s recorded because the adapter finished at the limit due to parallel slot contention.

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (24s) | 2/2 (7s) |
| qwen/qwen3.5-9b | 2/2 (14s) | 2/2 (6s) |
| google/gemma-4-26b-a4b-qat | 2/2 (11s) | 2/2 (14s) |
| qwen/qwen3-coder-30b | 2/2 (13s) | 2/2 (8s) |
| qwen/qwen3-coder-next | 2/2 (16s) | 2/2 (18s) |
