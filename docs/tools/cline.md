# cline

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Cline |
| **CLI command** | `cline` |
| **Version** | latest (pnpm store binary, cli-darwin-arm64) |
| **Adapter script** | [`adapters/cline-lms.sh`](../../adapters/cline-lms.sh) |
| **How it connects** | `cline auth openai-compatible` writes provider config to an isolated `--data-dir`; passes `--apikey`, `--modelid`, and `--baseurl` pointing at `LMS_BASE_URL`. Overwritten fresh each run. |
| **Last reviewed** | 2026-06-18 |

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

**Needs full benchmark run:** only smoke-tested so far (see Status). The tool-call agent loop may expose different failure modes on real coding cases (multi-file edits, lint/test iteration) than on the two smoke cases.

## Status

**under-evaluation** — adapter is functional; 100% on both smoke cases across 5 models (run `20260618-072539`, lms runtime). Not yet run on the full 10-case benchmark. Next step: `bin/bench --adapter cline` with a capable model to establish a full baseline.

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (21s) | 2/2 (22s) |
| qwen/qwen3.5-9b | 2/2 (17s) | 2/2 (31s) |
| google/gemma-4-26b-a4b-qat | 2/2 (31s) | 2/2 (22s) |
| qwen/qwen3-coder-30b | 2/2 (19s) | 2/2 (67s) |
| qwen/qwen3-coder-next | 2/2 (16s) | 2/2 (20s) |
