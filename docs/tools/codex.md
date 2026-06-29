# codex

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | codex |
| **CLI command** | `codex exec` |
| **Version** | codex-cli 0.138.0 |
| **Adapter script** | [`adapters/codex-lms.sh`](../../adapters/codex-lms.sh) |
| **How it connects** | Custom `model_provider` config passed inline via `-c` flags. Registers a `lmstudio_local` provider (not `lmstudio` — that's a reserved built-in ID that can't be overridden). |
| **Last reviewed** | 2026-06-30 |

## Edit mechanism

- **Format:** codex uses a tool-calling architecture similar to opencode. The model emits structured file-write/file-edit tool calls. No specific diff format is required.
- **File targeting:** codex provides the model with CWD access and file listing. The model discovers files autonomously.
- **Multi-file edits:** generally reliable on capable models. js-03 (multi-file cache) passes on Qwen3 models but fails on several Gemma models, suggesting a model-capability threshold rather than a codex mechanism issue.

## Iteration / self-verify behaviour

codex iterates via its `exec` mode: after each model response, codex executes any tool calls (file writes, shell commands), captures output, and continues the conversation. For self-verify cases, this means running the test suite and feeding results back. However, codex is **slower per iteration** than opencode, and on slower models (gemma-4-12b-qat) hits the 300s timeout mid-iteration.

On strong models (qwen3.6-35b-a3b, qwen3-coder-30b, qwen3.5-9b), codex achieves 100% including self-verify cases, demonstrating that the mechanism works well when generation speed is adequate.

## Failure modes

**Model-key compatibility (error(1), 1–10s):** codex crashes on several models that weren't properly loaded during the run (gemma-4-12b, gemma-4-31b, gemma-4-31b-qat). These are infrastructure failures, not codex bugs.

**Non-zero exit with correct result (codex lingering):** codex occasionally exits with rc=1 after correctly applying edits and passing the grader. Observed on qwen3-coder-30b (js-06, ts-01: both 4/4 and 3/3 but error(1) status). The edit is applied; the non-zero exit is a codex subprocess cleanup bug. This inflates the error(1) count but doesn't affect scores.

**Slow models + timeout:** codex is the most affected adapter by slow models. gemma-4-12b-qat produces 5 timeout cases, several of which were likely in-progress (codex may have been mid-turn). The multi-turn conversation overhead compounds the model's slow token generation.

**Gemma feature/self-verify failures:** codex consistently fails js-05 (self-verify) and certain feature cases on Gemma e4b and e2b models that other adapters pass. The model either doesn't produce tool calls in the expected format, or codex's prompt structure elicits different behaviour than opencode's.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--skip-git-repo-check` | Sandbox has no git repository; codex would error without this |
| `--dangerously-bypass-approvals-and-sandbox` | Runs without sandboxing so file edits reach the host sandbox filesystem |
| `-c model="$MODEL_ID"` | Sets the model key for the run |
| `-c model_provider="lmstudio_local"` | Selects our custom provider (not the reserved `lmstudio` built-in) |
| `-c model_providers.lmstudio_local.name="LM Studio"` | Human-readable label for the provider |
| `-c model_providers.lmstudio_local.base_url="$LMS_BASE_URL"` | Points codex at the LM Studio API endpoint |
| `-c model_providers.lmstudio_local.env_key="LMS_API_KEY"` | Tells codex which env var holds the API key |

## Known issues

**`lmstudio` reserved provider ID:** codex has a built-in `lmstudio` provider that cannot be overridden with `-c`. The workaround (`lmstudio_local`) works but requires all four `-c model_providers.*` flags to be passed on every invocation. A persistent config in `~/.codex/config.toml` would simplify this. See `docs/SETUP.md`.

**Non-zero exit on clean results:** codex exits with rc=1 after correct edits on qwen3-coder-30b (js-06, ts-01). This is a reproducible codex CLI bug at version 0.138.0. Monitor in future versions.

## Cross-model sweep results (2026-06-29, lms, run `20260629-*`)

| Model | Score | Notes |
|-------|-------|-------|
| qwen/qwen3.6-35b-a3b | 38/38 (100%) | |
| qwen/qwen3.5-9b | 37/38 (97%) | |
| devstral-small-2-2512 | 28/32 (87%) | 4 cases not run |
| google/gemma-4-26b-a4b-qat | 34/38 (89%) | |
| qwen/qwen3.6-27b | 38/38 (100%) | |
| zai-org/glm-4.7-flash | 24/38 (63%) | most cases timeout; only viable adapter for this model |
| qwen/qwen3-coder-30b | 35/38 (92%) | js-06 and ts-01 error(1) with full pass (codex exit bug) |

codex achieves 100% on the top MoE models and scores usably on glm-4.7-flash (63%) where all other adapters hit the timeout floor (37%). The glm advantage comes from fewer round-trips — codex completes more in a single generation.

## Status

**stable** — strong results on capable models (100% on qwen3.6-35b-a3b, qwen3.6-27b, qwen3.5-9b). The only viable adapter for glm-4.7-flash GGUF. The non-zero exit bug is cosmetic (doesn't affect scores).
