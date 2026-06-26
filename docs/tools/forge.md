# forge

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | forge (antinomyhq/forge) |
| **CLI command** | `forge` |
| **Version** | not yet evaluated |
| **Adapter script** | [`adapters/forge-lms.sh`](../../adapters/forge-lms.sh) |
| **How it connects** | `OPENAI_API_BASE` + `OPENAI_API_KEY` env vars; backend-agnostic, any `/v1/chat/completions` endpoint. |
| **Last reviewed** | 2026-06-26 |

## Background

[Forge](https://github.com/antinomyhq/forge) (antinomyhq, Rust) is a model-agnostic coding agent with a three-agent architecture:
- **forge** — implementation agent (default; edits code)
- **sage** — research agent (read-only; answers questions about the codebase)
- **muse** — planning agent (generates specs, no edits)

Supports 300+ models by design; backend-agnostic via OpenAI-compatible API. Written in Rust → fast startup, low overhead per request.

Why add it: the multi-agent split is architecturally distinct from any current adapter and stresses local models differently — the model must switch roles cleanly between planning and implementation turns.

## Edit mechanism

- **Format:** tool calls (OpenAI `tool_use` format); forge handles file reads, writes, and shell execution via structured tool invocations.
- **File targeting:** model discovers files autonomously via read tool calls.
- **Multi-file edits:** well-supported.

## Local model configuration

```bash
OPENAI_API_BASE=http://localhost:1234/v1 \
OPENAI_API_KEY=lm-studio \
forge --model <id> --no-confirm "task description"
```

Verify `--no-confirm` flag name against the installed version — CLI flags may differ between releases. Check `forge --help`.

## Iteration / self-verify behaviour

forge loops until the model completes the task. Shell execution (test running) is available via tool calls, so self-verify cases are in scope.

## Failure modes

- **Wrong flag names:** forge is a fast-moving Rust project; flag names changed between releases. Run `forge --help` to verify `--no-confirm` and `--model` exist.
- **Multi-agent confusion:** weak models may not switch roles cleanly between forge/sage/muse contexts. Likely manifests as planning output in an implementation turn or vice versa.
- **Tool-call format:** same failure mode as codex/opencode — models that emit prose instead of structured tool calls produce no edits.

## Note on naming

There are two projects called "forge" on GitHub:
- **antinomyhq/forge** (this one) — also called ForgeCode. Rust CLI agent.
- **antoinezambelli/forge** — Python agent framework. Different tool.

The adapter targets antinomyhq/forge.

## Install

```bash
# Binary from GitHub releases (recommended)
curl -L https://github.com/antinomyhq/forge/releases/latest/download/forge-$(uname -m)-apple-darwin.tar.gz | tar xz
mv forge /usr/local/bin/

# Or via cargo
cargo install forge-cli
```

## Status

**not yet benchmarked.** Adapter added 2026-06-26. Run smoke test first:

```bash
bin/smoke forge
```
