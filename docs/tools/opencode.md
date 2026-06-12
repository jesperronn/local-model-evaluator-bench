# opencode

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | opencode |
| **CLI command** | `opencode run` |
| **Version** | 1.16.2 |
| **Adapter script** | [`adapters/opencode-lms.sh`](../../adapters/opencode-lms.sh) |
| **How it connects** | Built-in `lmstudio` provider (models.dev auto-discovery from `http://localhost:1234`). Model addressed as `lmstudio/<MODEL_ID>`. Config via `~/.config/opencode/opencode.json`. |
| **Last reviewed** | 2026-06-09 |

## Edit mechanism

- **Format:** opencode uses a native tool-call based editing approach — the model emits structured file edit tool calls that opencode applies. The model does not need to produce a specific text diff format; it calls the edit tool with file path, old content, and new content.
- **File targeting:** opencode discovers files from the CWD autonomously. It does not require explicit file hints — the model can list the directory, read files, and target any file it finds.
- **Multi-file edits:** strong. opencode's tool-calling architecture handles multi-file edits cleanly in a single turn. js-03 and js-04 pass on most capable models where aider and codex fail.

## Iteration / self-verify behaviour

opencode iterates natively. For self-verify cases (js-05, js-06), opencode runs the provided test suite, captures output, feeds it back to the model, and continues until the tests pass or the model gives up. This makes it the strongest adapter for self-verify cases on capable models. js-05 and js-06 both pass at high rates when the model is capable (100% on qwen3.6-35b-a3b, qwen3-coder-30b, gemma-4-26b-a4b-qat).

## Failure modes

**Model-key compatibility (error(1), ~1s):** opencode crashes with error(1) in under 2 seconds on some models. This appears when `lmstudio/<MODEL_ID>` is not recognised by opencode's model catalogue or the response format is unexpected. Observed on: qwen3-coder-next (all 9 cases), some partial-run models. The crash is immediate — no edit is ever attempted.

**Near-zero with ok status (0 pass, 0–4s):** on some models (gemma-4-12b, gemma-4-31b, gemma-4-31b-qat), opencode returns ok status but completes in under 4s with 0 passes. This indicates a model-side failure — the model is responding but not producing useful tool calls. This is a model or key issue, not an opencode bug.

**Slow models + self-verify timeout:** on gemma-4-12b-qat, opencode hit the 300s timeout on bash-01 (with full pass) and js-06 (without pass). The timeout on js-06 was a genuine failure — the model was still iterating when the timer fired. The 300s limit is tight for slow 12B models doing multi-round self-verify.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--model lmstudio/${MODEL_ID}` | Selects the built-in lmstudio provider and routes to the loaded model |
| `"$PROMPT"` (positional) | Delivers the task as a single run invocation |

No other flags are used. opencode's defaults (tool-calling, auto file discovery, self-verify loop) are appropriate for the benchmark contract.

## Known issues

**qwen3-coder-next incompatibility:** opencode crashes with error(1) on all cases for this model. The model is otherwise capable (codex/caveman score 100%/97%). Suspected cause: the model's response format or the `lmstudio/qwen3-coder-next` key routing fails. Check opencode's model list and whether the model needs a config override in `~/.config/opencode/opencode.json`.

**Config dependency:** opencode reads its LM Studio base URL from `~/.config/opencode/opencode.json`. If the LM Studio server is not at `localhost:1234`, this must be pre-configured. See `docs/SETUP.md`.

## Status

**stable** — best overall adapter for multi-file and self-verify cases. The qwen3-coder-next incompatibility is a known blocker but doesn't affect the majority of models.

## Comparison with other adapters

opencode consistently outperforms aider on multi-file and self-verify cases. It's competitive with caveman on quality but generally slower. For models where both work, opencode is the reference adapter for evaluating true model capability — its tool-calling architecture removes edit-format as a confounding factor.
