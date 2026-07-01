# continue

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best model** | measured pending |
| **Recommended for** | measured pending |
| **Status** | broken |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Continue |
| **CLI command** | none known |
| **Version** | measured pending |
| **Adapter script** | likely not possible |
| **How it connects** | IDE extension (VS Code + JetBrains); no headless CLI mode documented |
| **Last reviewed** | never |

## Edit mechanism

- **Format:** IDE-driven/Chat
- **File targeting:** manual/IDE-driven
- **Multi-file edits:** none documented for headless use

## Iteration / self-verify behaviour
Not applicable; lacks a CLI-driven loop.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| measured pending | measured pending | measured pending | measured pending | measured pending |

## Capability notes
**Critical path weakness:** Lack of headless CLI or stdin/stdout interface prevents benchmarking in this harness.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| none | N/A |

## Failure modes
No repeatable failures documented due to lack of benchmarkable interface.

## Status
**broken** — Continue is an IDE extension, not a CLI agent. No stdin/stdout interface for benchmarking.

## Investigation notes

Continue (continue.dev) has excellent local model support via Ollama, LM Studio, and OpenAI-compatible providers, configured through `~/.continue/config.json`. However, the interaction model is chat and autocomplete inside the editor — not a shell-driven prompt→edit loop.

Angles that could change this:

- **`@continuedev/core` npm package** — check if it exposes a headless or programmatic API that could be scripted
- **Continue CLI mode** — check if any unreleased or experimental CLI has landed since last review
- **JetBrains Junie** is the JetBrains-native equivalent and has the same constraint

Until a headless mode is documented, Continue is better evaluated as a user experience (IDE UX, autocomplete quality) rather than benchmarked in this harness. Revisit if a CLI entry point appears.
