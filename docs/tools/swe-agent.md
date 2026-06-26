# swe-agent / mini-swe-agent

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | swe-agent + mini-swe-agent |
| **CLI command** | `sweagent run` / `mini-swe-agent` |
| **Version** | not yet evaluated |
| **Adapter scripts** | [`adapters/swe-agent-lms.sh`](../../adapters/swe-agent-lms.sh), [`adapters/mini-swe-agent-lms.sh`](../../adapters/mini-swe-agent-lms.sh) |
| **How it connects** | LiteLLM under the hood. Set `--model.api_base` (swe-agent) or `OPENAI_API_BASE` (mini-swe-agent) to `$LMS_BASE_URL`. Model name must be prefixed `openai/` to route through LiteLLM. |
| **Last reviewed** | 2026-06-26 |

## Background

[SWE-agent](https://swe-agent.com) (Princeton NLP, NeurIPS 2024) is the canonical benchmark scaffold that defined the SWE-bench leaderboard. It wraps a model in a shell loop with a custom Agent-Computer Interface (ACI) — specialised file-viewing, search, and edit commands designed to reduce the action space for language models working on real codebases.

**mini-swe-agent** is a ~100-line ReAct loop from the same team, released mid-2025. It strips the ACI down to bare essentials and scores >74% on SWE-bench Verified. Easier to trace; better for isolating model capability vs scaffold contribution.

Both are worth running:
- **swe-agent**: scores directly comparable to published leaderboard results.
- **mini-swe-agent**: lower overhead, faster per-case, better debugging signal.

## Edit mechanism

- **swe-agent:** ACI commands (`open`, `scroll_down`, `edit`, `search_file`, `bash`). Model emits structured ACI function calls; the scaffold executes them in a Docker container or local shell.
- **mini-swe-agent:** ReAct loop — model emits `<action>...</action>` blocks; scaffold parses and runs them.

Both route file edits through their own format; neither uses aider-style diffs or OpenAI tool_call JSON directly. Format compliance is the main failure mode for weaker local models.

## Local model configuration

Both use LiteLLM routing:

```bash
# swe-agent
sweagent run \
  --model.name "openai/<id>" \
  --model.api_base "http://localhost:1234/v1" \
  --model.api_key "lm-studio" \
  --model.cost_tracking ignore_errors   # required — LiteLLM tries to price-check local models

# mini-swe-agent
OPENAI_API_BASE=http://localhost:1234/v1 \
OPENAI_API_KEY=lm-studio \
mini-swe-agent --model "openai/<id>" --repo-path . --problem-statement "..."
```

`cost_tracking ignore_errors` is **required** for swe-agent with local models — without it the run aborts when LiteLLM can't look up the price for an unknown model id.

## Iteration / self-verify behaviour

swe-agent runs a multi-turn loop until the model signals it is done or a step limit is hit. It is inherently self-verifying — it can run tests and incorporate the output. mini-swe-agent similarly loops but with fewer scaffolded actions.

Both are significantly **slower per case** than adapters like aider or codex because they warm-start a shell environment per case. Plan for a higher timeout (`--timeout 600` in bench).

## Failure modes

- **ACI format errors:** model emits prose instead of ACI commands → no edits applied, loop stalls.
- **Step limit exceeded:** weak models take many small steps; default limits (30–50) may be too low.
- **cost_tracking abort:** forgetting `ignore_errors` on swe-agent causes immediate abort for any unrecognised local model id.
- **Docker requirement (swe-agent):** full swe-agent runs in Docker by default. Pass `--env.repo.path $(pwd)` to use a local checkout instead.

## Install

```bash
pip install swe-agent        # full variant
pip install mini-swe-agent   # lightweight variant
```

## Status

**not yet benchmarked.** Adapters added 2026-06-26. Run smoke test first:

```bash
bin/smoke swe-agent
bin/smoke mini-swe-agent
```
