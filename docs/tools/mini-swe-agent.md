# mini-swe-agent

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best model** | measured pending |
| **Recommended for** | measured pending |
| **Status** | ready for benchmarking |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | mini-swe-agent |
| **CLI command** | `mini-swe-agent` |
| **Version** | 2.4.2 (installed 2026-06-27) |
| **Adapter script** | [`adapters/mini-swe-agent-lms.sh`](../../adapters/mini-swe-agent-lms.sh) |
| **How it connects** | Routes through LiteLLM; `OPENAI_API_BASE` + `OPENAI_API_KEY` env vars; model addressed as `openai/<MODEL_ID>` |
| **Last reviewed** | 2026-06-27 |

## Background

[mini-swe-agent](https://mini-swe-agent.com) is the minimal SWE-agent variant
(~100 lines of agent code vs. the full SWE-agent framework), still scoring
>74% on SWE-bench Verified. Chosen over full swe-agent for faster per-case
execution and easier debugging of model behavior.

Install:

```bash
python3 -m pip install --break-system-packages mini-swe-agent
```

## v1 → v2 migration notes

- v1 used `--problem-statement`; v2 uses `--task`.
- v1 used `--repo-path`; v2 operates in the current working directory only —
  no need to pass a repo path, just `cd` into the sandbox first.
- See the [v2 usage docs](https://mini-swe-agent.com/latest/usage/mini/) for
  the full CLI reference.

## Edit mechanism

- **Format:** LiteLLM-routed tool calls (`litellm_model` class, the v2 default).
- **File targeting:** operates in the adapter's working directory (CWD);
  no explicit `--repo-path` needed in v2.
- **Multi-file edits:** not yet measured — pending a full benchmark run.

## Iteration / self-verify behaviour

Not yet measured.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| measured pending | measured pending | measured pending | measured pending | measured pending |

## Capability notes

- Requires the Python bin directory on `PATH` (the adapter hardcodes
  `/Users/jesper/Library/Python/3.14/bin` — adjust for other machines).
- No auto-approve flag is used (`--yolo` etc.), matching the project's
  [no-auto-approve policy](../WORKFLOW.md#conventions).

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--model openai/<id>` | Routes through LiteLLM's generic OpenAI-compatible backend at `$OPENAI_API_BASE`. |
| `--task` | v2 CLI flag for the problem statement (stdin task text), replacing v1's `--problem-statement`. |

## Status

**Not yet benchmarked.** Adapter installed and wired 2026-06-27. Run a smoke
test first:

```bash
bin/smoke mini-swe-agent
```
