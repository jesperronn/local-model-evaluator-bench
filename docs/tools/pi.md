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

**Needs full benchmark run:** only smoke-tested so far (see Status). pi's agent loop may surface different failure modes on real coding cases than on smoke. Its relationship with caveman (which also uses the pi runtime under the hood) is worth investigating — they may share failure patterns.

**Caveman shares the pi runtime:** `caveman` is also built on the pi agent runtime. If both are run concurrently in `bin/bench`, they share the same `~/.pi/agent/models.json` config. Verify they use separate config paths or run them in separate slots.

## Status

**under-evaluation** — adapter is functional; 100% on both smoke cases across 5 models (run `20260618-072539`, lms runtime). Not yet run on the full 10-case benchmark. Next step: `bin/bench --adapter pi` with a capable model to establish a full baseline and compare against `caveman` (which also uses the pi runtime).

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (24s) | 2/2 (7s) |
| qwen/qwen3.5-9b | 2/2 (14s) | 2/2 (6s) |
| google/gemma-4-26b-a4b-qat | 2/2 (11s) | 2/2 (14s) |
| qwen/qwen3-coder-30b | 2/2 (13s) | 2/2 (8s) |
| qwen/qwen3-coder-next | 2/2 (16s) | 2/2 (18s) |
