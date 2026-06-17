# kilocode

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Kilo Code |
| **CLI command** | `kilocode` (likely) |
| **Version** | unknown — not yet evaluated |
| **Adapter script** | not yet written |
| **How it connects** | TBD — Kilo Code is a Cline fork; likely shares the same openai-compatible provider architecture |
| **Last reviewed** | never |

## Status

**not evaluated** — candidate for local model support.

## Investigation notes

Kilo Code is a fork of Cline. If it shares the same architecture, the adapter approach should be nearly identical to `adapters/cline-lms.sh`: write a `providers.json` into an isolated `--data-dir` pointing at LM Studio or Ollama.

Things to check:

- Install: check kilocode.ai or `npm install -g kilocode`
- Does it accept `--data-dir` like cline?
- Does it use the same `providers.json` format as cline (v1 with `openai-compatible` key)?
- Does `--auto-approve true` work the same way for headless runs?
- Any divergence from cline in the CLI flag interface?

If the data-dir approach works, `adapters/kilocode-lms.sh` is a copy-paste of `adapters/cline-lms.sh` with `cline` replaced by `kilocode`.
