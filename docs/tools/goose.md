# goose

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | goose (Block Goose) |
| **CLI command** | `goose run` (likely) |
| **Version** | unknown — not yet evaluated |
| **Adapter script** | not yet written |
| **How it connects** | TBD — investigate whether it accepts an OpenAI-compatible base URL via env var or config file |
| **Last reviewed** | never |

## Status

**not evaluated** — candidate for local model support.

## Investigation notes

Goose is Block's open-source AI coding agent. It appears to support configurable providers, likely via a config file or env vars. Since it targets OpenAI-compatible APIs this should be adaptable the same way as cline or opencode.

Things to check:

- Install: `pip install goose-ai` or check docs at https://block.github.io/goose/
- Does `goose --help` expose a `--base-url` or `--provider` flag?
- Is there a config file (e.g. `~/.config/goose/`) where the provider base URL can be set?
- Can it be driven non-interactively with a prompt argument (stdin or positional)?
- Does it support tool-calling or does it use a text diff format?

If a headless mode and OpenAI-compatible provider config exist, write `adapters/goose-lms.sh` and `adapters/goose-ollama.sh`.
