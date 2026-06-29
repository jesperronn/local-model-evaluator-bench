# cline

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Cline |
| **CLI command** | `cline` |
| **Version** | latest (pnpm store binary, cli-darwin-arm64) |
| **Adapter script** | [`adapters/cline-lms.sh`](../../adapters/cline-lms.sh) |
| **How it connects** | `cline auth openai-compatible` writes provider config to an isolated `--data-dir`; passes `--apikey`, `--modelid`, and `--baseurl` pointing at `LMS_BASE_URL`. Overwritten fresh each run. |
| **Last reviewed** | 2026-06-30 |

## Edit mechanism

- **Format:** Cline uses tool calls (read_file, write_to_file, execute_command, etc.) via an agent loop. The model must emit well-formed JSON tool calls; Cline applies them and loops until done.
- **File targeting:** autonomous — Cline discovers files via its own read/list tools.
- **Multi-file edits:** tool-call architecture supports it natively; expected to be reliable on capable models.

## Iteration / self-verify behaviour

Cline runs as an autonomous agent loop. For self-verify cases (js-05, js-06), Cline can run the test suite via `execute_command` and iterate. This is a strength over single-shot adapters (aider, caveman in non-loop mode).

## Failure modes

**pnpm global install broken:** `pnpm install -g cline` is currently broken (global/v11 path missing). The adapter falls back to the latest `cli-darwin-arm64` binary in the pnpm store. Fix: `pnpm install -g cline` once pnpm resolves the global path issue.

**`--auto-approve true` scope:** the adapter passes `--auto-approve true` for unattended runs. Cline may still prompt for certain destructive operations depending on version.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--data-dir $DATA_DIR` | Isolates Cline's SQLite DBs and provider config from the user's real Cline install |
| `-P openai-compatible` | Selects the provider configured via `cline auth` |
| `--model "$MODEL_ID"` | Overrides the model at runtime |
| `--auto-approve true` | Unattended benchmark mode; skips interactive confirmations |

## Known issues

**pnpm global install broken:** `pnpm install -g cline` is currently broken (global/v11 path missing). The adapter falls back to the latest `cli-darwin-arm64` binary in the pnpm store.

**Auth re-init per run:** `cline auth openai-compatible` is called fresh each bench run, which avoids stale config but adds ~1–2s overhead per case.

## Observations across runs

### 2026-06-18 — first run (`20260618-190652`, lms, `qwen/qwen3.6-35b-a3b`)

Three early cases returned `error(1)` with partial scores:
- bash-01-topwords: 0/4, error(1), 45s
- js-01-slugify-bug: 2/4, error(1), 45s
- js-02-debounce-feature: 3/4, error(1), 26s

js-03 through ts-01 all passed cleanly. The partial scores on js-01 (2/4) and js-02 (3/4) indicate edits were being applied before cline crashed — the failure is in exit/cleanup, not in the editing loop. Likely a binary resolution or provider init instability during pnpm store path lookup on the first invocations. Re-run resolved all three.

### 2026-06-18 — second run (`20260618-190854`, lms, `qwen/qwen3.6-35b-a3b`)

36/36 100%. All cases clean. js-06 hit the 300s timeout but all assertions passed before the harness killed the process.

## Status

**stable** — full 10-case benchmark completed 2026-06-18 (lms runtime, `qwen/qwen3.6-35b-a3b`): 36/36 points (1.00). js-06-lint-and-test hit the 300s timeout but still passed all assertions.

### Full benchmark results (2026-06-18, lms, run `20260618-190854`)

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| bash-01-topwords | 4/4 (1.00) | 296s | ok |
| js-01-slugify-bug | 4/4 (1.00) | 97s | ok |
| js-02-debounce-feature | 4/4 (1.00) | 85s | ok |
| js-03-multifile-cache | 5/5 (1.00) | 132s | ok |
| js-04-multifile-rename | 3/3 (1.00) | 93s | ok |
| js-05-multiselect-filter | 5/5 (1.00) | 292s | ok |
| js-06-lint-and-test | 4/4 (1.00) | 300s | timeout |
| smoke-00-hello | 2/2 (1.00) | 31s | ok |
| smoke-01-edit-file | 2/2 (1.00) | 51s | ok |
| ts-01-groupby | 3/3 (1.00) | 108s | ok |
| **Total** | **36/36 (1.00)** | | |

### Full sweep results (2026-06-29, lms, run `20260629-*`)

| Model | Score | Notes |
|-------|-------|-------|
| qwen/qwen3.6-35b-a3b | 38/38 (100%) | All 11 cases PASS |
| qwen/qwen3.5-9b | 34/38 (89%) | 4 cases FAIL/WARN |
| devstral-small-2-2512 | 33/38 (86%) | |
| google/gemma-4-26b-a4b-qat | 34/38 (89%) | |
| qwen/qwen3.6-27b | 28/34 (82%) | Dense model — slower, some timeouts |
| zai-org/glm-4.7-flash | 12/32 (37%) | Timeout floor — GGUF too slow |

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (21s) | 2/2 (22s) |
| qwen/qwen3.5-9b | 2/2 (17s) | 2/2 (31s) |
| google/gemma-4-26b-a4b-qat | 2/2 (31s) | 2/2 (22s) |
| qwen/qwen3-coder-30b | 2/2 (19s) | 2/2 (67s) |
