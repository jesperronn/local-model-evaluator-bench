# cn

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% (32/32) on qwen/qwen3.6-35b-a3b, full case set |
| **Speed (avg)** | ~100s per case |
| **Best model** | qwen/qwen3.6-35b-a3b (only model tested so far) |
| **Recommended for** | autonomous multi-file edits, self-verify loops |
| **Status** | stable |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | cn (Continue's headless CLI) |
| **CLI command** | `cn` |
| **npm package** | `@continuedev/cli` |
| **Version** | 1.5.47 |
| **Adapter script** | [`adapters/cn-lms.sh`](../../adapters/cn-lms.sh) |
| **How it connects** | Generates a per-run `~/.continue-lms-adapter/config.yaml` (`provider: openai`, `apiBase: $LMS_BASE_URL`, `model: $MODEL_ID`), then runs `cn --config <file> -p --auto --silent "<prompt>"` |
| **Last reviewed** | 2026-07-01 |

> **Not the Continue.dev VS Code/JetBrains GUI extension.** `cn` is a separate headless CLI product from the same team. See [docs/extensions/continue.md](../extensions/continue.md) for why the GUI extension is currently ranked "avoid" (approval-memory failure) while this CLI is fully usable for automated benchmarking — the GUI's approval-prompt UI doesn't exist in headless mode.

## Edit mechanism

- **Format:** tool-call driven agent loop (read/write/execute tools), not a diff-block format like aider. The model doesn't need to emit a specific text format — `cn` handles file I/O via its own tool schema.
- **File targeting:** autonomous — `cn` discovers and edits files itself via its own read/list/write tools, no `--file` hints needed.
- **Multi-file edits:** native and reliable — js-03 (5/5) and js-04 (3/3) both passed cleanly on the only model tested.

## Iteration / self-verify behaviour

`cn --auto` runs a full autonomous agent loop: it can execute shell commands (e.g. run a test suite) and iterate on failures before returning. js-06-lint-and-test (the self-verify case) passed 4/4 in 181s — the slowest case in the set, consistent with an iterate-until-green loop rather than a single-shot attempt.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| qwen/qwen3.6-35b-a3b | 100% (32/32) | ~100s | lms | 2026-07-01 baseline run; all 8 cases (bash-01, js-01–js-06, ts-01) passed, including both multi-file cases and the self-verify case |

Only one model tested so far — this adapter is new (added 2026-07-01). Broaden to other models in the standard roster (qwen3-coder-30b, qwen3.5-9b, gemma-4-26b-a4b-qat, etc.) via `bin/bench --agent cn --model <id>`.

## Capability notes

- **Tool-editing reliability:** no known blockers — 100% across every case type tried (single-file, multi-file, self-verify) on the one model tested.
- **Headless mode caveat:** `--auto` auto-approves every tool call with zero interactive prompting. This is exactly what makes it benchmarkable, but it also means these numbers say nothing about the GUI extension's interactive approval-prompt UX, which is evaluated separately in [docs/extensions/continue.md](../extensions/continue.md) (and is currently disqualifying there).
- **Naming:** the adapter is named `cn`, not `continue` — `bin/bench` resolves adapters via `command -v "$adapter"`, and `continue` collides with the bash builtin of that name.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--config "$CONFIG_FILE"` | Points `cn` at a per-run generated YAML config with `provider: openai`, `apiBase: $LMS_BASE_URL`, `model: $MODEL_ID` — regenerated every invocation so `$MODEL_ID` always matches the current adapter call |
| `-p` (`--print`) | Headless print-and-exit mode; prints the final response instead of starting an interactive session |
| `--auto` | Auto mode — allows all tools with no interactive approval prompt, required for non-interactive/scripted use |
| `--silent` | Strips `<think></think>` reasoning tags and excess whitespace from output |

## Failure modes

None observed yet — 32/32 across every case tried. Revisit once more models are run; expect the usual failure classes (tool-format friction on weaker/smaller models, timeouts on slow dense models) to eventually show up as the model roster broadens.

## Status

**stable** — 2026-07-01: adapter added and verified 100% (32/32) on qwen/qwen3.6-35b-a3b across the full 8-case set, including multi-file and self-verify cases. Single-model result so far; broaden the model roster before treating this as a fully mature entry in the leaderboard comparisons.
