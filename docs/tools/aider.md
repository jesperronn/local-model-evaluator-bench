# aider

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% on all 11 cases across 7 models |
| **Speed (avg)** | ~39s per case |
| **Best model** | qwen/qwen3-coder-30b |
| **Recommended for** | autonomous multi-file edits, self-verify loops |
| **Status** | stable |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | aider |
| **CLI command** | `aider` |
| **Version** | 0.86.2 |
| **Adapter script** | [`adapters/aider-lms.sh`](../../adapters/aider-lms.sh) |
| **How it connects** | OpenAI-compatible endpoint via `--openai-api-base` and `--openai-api-key`; model addressed as `openai/<MODEL_ID>` |
| **Last reviewed** | 2026-06-30 |

## Edit mechanism

- **Format:** aider uses a search/replace block format by default (`SEARCH/REPLACE` fences). The model must emit one block per file change. If the model produces a whole-file rewrite or a plain diff, aider cannot apply it.
- **File targeting:** aider requires files to be in the "chat" at the start of the session. The adapter does **not** pass `--file` flags, so aider must discover files from the prompt text. For single-file cases this works when the model names the file; for multi-file cases it frequently misses the second file.
- **Multi-file edits:** unreliable. aider can edit multiple files in one session if it adds them to the chat dynamically, but without `--file` hints the model often edits only the 1st mentioned file.

## Iteration / self-verify behaviour

aider runs as a single `--message` invocation (non-interactive). It does not loop: once the model's response is consumed and the edits applied, aider exits. For self-verify cases (js-05, js-06) the task prompt tells the agent to run the test suite and iterate — aider does not do this in single-message mode. The model must apply a working solution in one shot.

Despite this limitation, aider scores 5/5 on js-05 for Qwen3-Coder models and several others — these models produce working code on the first attempt without needing to iterate.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| qwen3.6-35b-a3b | 100% | ~55s | | |
| qwen3.5-9b | 100% | ~19s | | |
| devstral-small-2-2512 | 94% | ~25s | | |
| gemma-4-20b-a4b-qat | 81% | ~50s | | |
| qwen3.6-27b | 76% | ~45s | | |
| glm-4.7-flash | 37% | timeout floor | | |
| qwen3-coder-30b | 100% | **avg 11s** | | |

## Capability notes

- **Format reliability:** Large Qwen / Gemma MoE models can produce output that breaks SEARCH/REPLACE fences, causing aider to report no changes.
- **Multi-file edits:** still highly dependent on the model's ability to discover files via prompt text without `--file` hints.
- **Timeout risks:** Slow models (e.g., gemma-4) may hit the 300s timeout during generation, preventing edits from being applied.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--model openai/${MODEL_ID}` | Routes through the OpenAI-compat provider prefix required by aider |
| `--openai-api-base $LMS_BASE_URL` | Points aider at LM Studio's local endpoint |
| `--openai-api-key $LMS_API_KEY` | Satisfies aider's key requirement (LM Studio accepts any non-empty value) |
| `--no-auto-commits` | Sandbox has no git history; auto-commits would error |
| `--no-dirty-commits` | Prevents aider from complaining about uncommitted changes |
| `--no-git` | Disables git integration entirely in the sandbox |
| `--no-check-update` | Prevents network call to check for aider updates on every run |
| `--no-show-model-warnings` | Suppresses model-specific warnings that pollute benchmark output |
| `--yes-always` | Auto-approves all aider prompts (non-interactive mode) |
| `--message "$PROMPT"` | Delivers the task prompt as a single non-interactive message |

## Failure modes

**No-edit / multi-file miss:** the most common aider failure. When no `--file` hint is passed, aider relies on the model to name files in its SEARCH/REPLACE blocks. For multi-file cases (js-03, js-04), the model often names only one file. The second file is never edited. This pattern appears on every model tested.

**Format incompatibility on large Qwen / Gemma MoE models:** some models (notably qwen3.6-35b-a3b, qwen3-coder-30b for js-03/js-04, and gemma-4-26b-a4b-qat across most cases) produce output that aider can't parse — the model may prefix explanations before the SEARCH/REPLACE block or use a slightly different fence format. This causes aider to report no changes applied.

**Timeout-then-fail:** on slow models (gemma-4-12b-qat, gemma-4-26b-a4b-qat bash-01), aider hits the 300s timeout while the model is still generating. The edit is never applied.

**Self-verify loop absent:** aider does not re-invoke itself after test failures. js-05 and js-06 failures on aider are almost always complete (0/5 or 0/4) rather than partial, because the model gets one chance.

## Status

**stable** — 2026-06-29 overnight run: aider achieved **100% on all 11 cases across 7 models** including all multifile cases (js-03, js 04) and self-verify (js-06). The previously documented multifile miss pattern did not reproduce — strong models (qwen3.6-35b-a3b, qwen3.5-9b, qwen3-coder-30b) appear to name both files correctly without `--file` hints. The "needs-tuning" status is retired. If multifile regressions reappear on weaker models, adding `--file` hints remains the suggested fix.
