# caveman

> **Not a candidate for evaluation.** `@caveman-ai/cli` is a wrapper around an agent that already has its own model config, not a harness that runs a prompt against a model. The old package is in [archived/caveman-code.md](../archived/caveman-code.md).

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | not evaluated (out of scope) |
| **Speed (avg)** | not evaluated (out of scope) |
| **Best model** | not applicable |
| **Recommended for** | not applicable for this bench |
| **Status** | not a candidate |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | caveman |
| **CLI command** | `caveman` (alias `cave`) |
| **npm package** | `@caveman-ai/cli` 4.0.1 (distinct from the archived `@juliusbrussee/caveman-code`) |
| **Adapter script** | [`adapters/caveman.sh`](../../adapters/caveman.sh) — targets the old CLI, does not work with this one |
| **How it connects** | Wraps another agent (`caveman run --off -- <agent> …`). No `--provider`/`--model` options. |
| **Runtime model discovery** | not applicable — caveman does not select or discover models |
| **Last reviewed** | 2026-10-19 |

## Edit mechanism

Not applicable — edits come from the wrapped agent.

## Iteration / self-verify behaviour

Not applicable — inherited from the wrapped agent.

## Results by model

No runs. Not evaluated.

## Capability notes

- Pass-through only; `--off` adds nothing to the run (tested with pi against a local endpoint, 2026-10-19).
- Compression needs companion binaries that are not installed, and was not tested.
- `caveman setup` changes 13 config files and enables Caveman Cloud routing by default. Do not run it on the bench machine without review.

## Adapter flags and their rationale

Not applicable. The flags in `adapters/caveman.sh` (`--provider`, `--model`, `--print`) do not exist in this CLI.

## Failure modes

Not applicable — not evaluated.

## Status

**not a candidate for evaluation** (decided 2026-10-19). Reconsider only if compression is shown to add value on the bench.
