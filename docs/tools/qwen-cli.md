# qwen (Qwen Code CLI)

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Qwen Code CLI |
| **CLI command** | `qwen` (likely) |
| **Version** | unknown — not yet evaluated |
| **Adapter script** | not yet written |
| **How it connects** | TBD — Qwen models run locally via Ollama; investigate if the CLI accepts an OpenAI-compatible base URL |
| **Last reviewed** | never |

## Status

**not evaluated** — candidate for local model support.

## Investigation notes

Qwen Code CLI is Alibaba's coding agent. Qwen models (e.g. `qwen2.5-coder`, `qwen3-coder`) are already available and well-benchmarked locally via Ollama and LM Studio. The question is whether the *CLI tool itself* can be pointed at a local endpoint.

Things to check:

- Does `qwen --help` expose a `--base-url` or `--api-base` flag?
- Is there a config file for provider overrides?
- If no native flag, does the proxy approach work (like `adapters/codex-proxy-ollama.sh`)?
- Can it run non-interactively from stdin?
- Does it use tool-calling or text diff editing?

Note: the benchmark already runs Qwen *models* via other adapters (codex, opencode, cline). This investigation is specifically about the Qwen Code *CLI agent* as a tool to evaluate separately.
