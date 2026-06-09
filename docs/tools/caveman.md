# caveman

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | caveman |
| **CLI command** | `caveman` |
| **Version** | <!-- TODO: `caveman --version` did not produce output --> |
| **Adapter script** | [`adapters/caveman.sh`](../../adapters/caveman.sh) |
| **How it connects** | Uses a `pi`-based agent runtime with a custom `lmstudio` provider definition in `~/.pi/agent/models.json` (baseUrl `http://localhost:1234/v1`, api `openai-completions`). |
| **Last reviewed** | 2026-06-09 |

## Edit mechanism

- **Format:** caveman uses a compact "caveman encoding" prompt style — compressed, token-efficient task descriptions. The model emits edits in a format the `pi` runtime applies to files in CWD. The exact edit format depends on the `--print` flag behaviour.
- **File targeting:** caveman operates on the CWD. Files are discovered autonomously; no explicit file hints are required.
- **Multi-file edits:** generally reliable on capable models. js-03 and js-04 pass on Qwen3 models. On small Gemma models (e2b, e4b), js-03 often fails — a model capability limitation rather than a caveman mechanism issue.

## Iteration / self-verify behaviour

caveman iterates through test results natively. For self-verify cases (js-05, js-06), the `pi` runtime runs the provided test suite and feeds results back to the model. On capable models, js-05 and js-06 pass at high rates (5/5 and 4/4). Self-verify performance is comparable to opencode.

Notably, caveman achieves strong self-verify results on larger models: qwen3.6-35b-a3b, qwen3-coder-30b, qwen3-coder-next, gemma-4-26b-a4b-qat all score 5/5 on js-05 and 4/4 on js-06 under caveman.

## Failure modes

**Infrastructure errors on partial-run models:** caveman exits with error(1) on models that weren't properly loaded (gemma-4-12b, gemma-4-31b, gemma-4-31b-qat). These are infrastructure failures.

**Compact prompt under-specification:** the caveman encoding is token-efficient but occasionally under-specifies the task for smaller models. Examples:
- gemma-4-e2b: caveman fails js-02-debounce-feature (0/4) where aider succeeds (4/4)
- gemma-4-e2b-qat: caveman fails ts-01-groupby (0/3) where others succeed
- qwen3.5-9b: caveman hits a timeout on js-02 (0/1, 300s) where others pass

This pattern is more common on sub-8B models, suggesting the compact encoding requires more model capacity to interpret correctly.

**Lingering on self-verify (timeout with pass):** caveman occasionally stays running after completing a self-verify case, hitting the 300s timeout with a correct result. Observed on gemma-4-12b-qat js-05 (5/5, timeout) and qwen3.5-9b js-05 (5/5, no timeout but long). The edit and tests pass; caveman doesn't exit cleanly. Not a quality issue.

**js-03-multifile-cache on qwen3-coder-next (0/1):** caveman fails js-03 for qwen3-coder-next where codex passes 5/5. The multi-file cache case requires edits to two specific files; caveman's compact prompt may not communicate the second file clearly enough to this model.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--provider lmstudio` | Selects the LM Studio provider defined in `~/.pi/agent/models.json` |
| `--model "$MODEL_ID"` | Sets the model key |
| `--print` | Runs non-interactively and prints the result (required for bench harness) |
| `"$PROMPT"` (positional) | Delivers the task as a single invocation |

## Known issues

**Version not reported:** `caveman --version` produces no output. The installed version is unknown. Monitor for changes that might affect behaviour.

**Provider config external to adapter:** the `lmstudio` provider definition lives in `~/.pi/agent/models.json`. If this file is missing or the LM Studio base URL is different, the adapter fails silently. See `docs/SETUP.md`.

## Status

**stable** — second-best adapter overall (87.1% across all models), trades blows with opencode. Faster than opencode on most models. The compact encoding occasionally under-specifies tasks for sub-8B models, but on capable models it is highly reliable.

## Comparison with other adapters

caveman is the speed/quality sweet spot: faster than codex, comparable quality to opencode on large models, and more reliable than aider on multi-file cases. For models where both opencode and caveman work, caveman is often the faster choice with similar quality. The compact encoding is its distinguishing characteristic — it may explain why some models perform differently under caveman vs other adapters.
