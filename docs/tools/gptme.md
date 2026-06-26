# gptme

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | gptme |
| **CLI command** | `gptme` |
| **Version** | not yet evaluated |
| **Adapter script** | [`adapters/gptme-lms.sh`](../../adapters/gptme-lms.sh) |
| **How it connects** | `OPENAI_BASE_URL` + `OPENAI_API_KEY` env vars; model addressed as `openai/<id>`. |
| **Last reviewed** | 2026-06-26 |

## Background

[gptme](https://gptme.org) (2023) is one of the oldest open CLI agents still actively maintained. It supports long-lived agents with git-backed memory, background jobs, web browsing, and a plugin system. Notable for having its own benchmarking tool (`gptme-bench`) covering tasks similar to this harness, making cross-comparison easier.

Why add it: different agent architecture than aider/codex/opencode — gptme has a richer tool set (shell, Python, browser, patch) and a longer context management strategy. Interesting for measuring how local models handle a more capable scaffold.

## Edit mechanism

- **Format:** gptme uses patch-style edits via its `patch` tool, or full file writes via `save`. Also supports direct shell commands (`shell` tool).
- **File targeting:** model discovers files via `read` tool calls and decides what to edit autonomously.
- **Multi-file edits:** well-supported via multiple tool invocations per turn.

## Local model configuration

```bash
OPENAI_BASE_URL=http://localhost:1234/v1 \
OPENAI_API_KEY=lm-studio \
gptme --model openai/<id> --workspace . --no-confirm "task description"
```

`--no-confirm` skips interactive approval prompts — required for harness use. Without it gptme pauses for user confirmation before executing shell commands.

## Iteration / self-verify behaviour

gptme loops until the model stops emitting tool calls. It supports running tests and reading back output, so self-verify cases (js-06-lint-and-test) are in scope. The `--no-confirm` flag is essential — without it the loop blocks on every shell execution.

## Failure modes

- **Confirmation prompts without --no-confirm:** loop hangs on any shell tool call.
- **Model not emitting tool calls:** gptme relies on models that can follow its tool-call format. Weaker models may emit prose instead → no edits.
- **Workspace not set:** without `--workspace`, gptme uses a default workspace and may not find the sandbox files.

## Own benchmark

gptme ships `gptme-bench` which runs a task set and reports pass rates. If you want to compare your local model results to gptme's own published numbers, run both: this harness gives you cross-adapter comparability; gptme-bench gives you gptme-specific absolute numbers.

## Install

```bash
pip install gptme
```

## Status

**not yet benchmarked.** Adapter added 2026-06-26. Run smoke test first:

```bash
bin/smoke gptme
```
