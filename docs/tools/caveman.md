# caveman

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 8points 71% across all models (pre-2026-06-28 data; see Version history) |
| **Speed (avg)** | measured pending |
| **Best model** | qwen3.6-35b-a3b |
| **Recommended for** | token-efficient task descriptions |
| **Status** | stable (fixed 2026-07-07 — was broken 2026-06-28 to 2026-07-07) |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | caveman |
| **CLI command** | `caveman` (aliases `caveman-code`) |
| **npm package** | `@juliusbrussee/caveman-code` (current — a distinct package from `pi`, not a `pi` fork/wrapper) |
| **Version** | 0.65.2 (checked 2026-07-07 via `caveman --version`) |
| **Adapter script** | [`adapters/caveman-lms.sh`](../../adapters/caveman-lms.sh), [`adapters/caveman-ollama.sh`](../../adapters/caveman-ollama.sh) |
| **How it connects** | `--provider lmstudio` selects a custom provider defined in `~/.cave/agent/models.json` (baseUrl `http://127.0.0.1:1234/v1`, api `openai-completions`) — same JSON schema as [pi's](pi.md) `~/.pi/agent/models.json`, but its own file/directory (`~/.cave/agent/`, not `~/.pi/agent/`). |
| **Runtime model discovery** | **no** — manual model list in `~/.cave/agent/models.json`, kept in sync by `bin/agents-config --agent caveman` (mirrors the pi sync path — see `config-templates/caveman-agent-models.json`). |
| **Last reviewed** | 2026-07-07 |

## Version history (last working → broken → fixed)

| Date | State | What was true |
|------|-------|----------------|
| ≤ 2026-06-25 | **working** | caveman ran on a `pi`-based runtime; custom providers lived in `~/.pi/agent/models.json` (shared with `pi`). All "Results by model" / "Failure modes" data below this line predates the break and reflects this working configuration. |
| 2026-06-28 | **broken** | `caveman` was repointed at (or upgraded to) `@juliusbrussee/caveman-code` — a separate, unrelated npm package (own `~/.cave/agent/` config dir, own binary). Nobody had created `~/.cave/agent/models.json` for it yet, so `--provider lmstudio` had no provider to resolve. `adapters/caveman-lms.sh` was patched that day to fail fast with a clear error instead of hanging, and the error was misdiagnosed as "caveman-code doesn't support local providers at all." |
| 2026-07-07 (found) | **misdiagnosed as unfixable** | A one-off re-run surfaced the same fail-fast error and was initially logged here as a fresh "regression" with no fix path. That framing was wrong — the capability was never removed from the tool, it was just never configured. |
| 2026-07-07 (fixed, lmstudio) | **working again** | Inspected `@juliusbrussee/caveman-code`'s `dist/core/model-registry.js`: it reads `~/.cave/agent/models.json` with the exact same `{providers: {name: {baseUrl, api, apiKey, models:[{id}]}}}` schema pi uses. Created `config-templates/caveman-agent-models.json` (lmstudio + ollama providers) and the live `~/.cave/agent/models.json`, wired `bin/agents-config --agent caveman` to keep it in sync the same way pi's is synced, and restored `adapters/caveman-lms.sh` to actually invoke `caveman --provider lmstudio --model "$MODEL_ID" --print`. Verified end-to-end via `bin/bench --agent caveman --models qwen/qwen3.5-9b --cases smoke-01-edit-file,js-01-slugify-bug` → 6/6 (100%), and again on `qwen/qwen3-coder-30b`. |
| 2026-08-30 (fixed, mtplx) | **working again** | `adapters/caveman.sh` had a hard-coded refusal branch for `mtplx` left over from before MTPLX support existed anywhere in the harness ("MTPLX not supported by caveman"). Same root cause pattern as the lmstudio/ollama fixes above: caveman-code's `~/.cave/agent/models.json` schema supports any OpenAI-compatible provider, mtplx was just never wired up. Removed the refusal branch, added `mtplx` to the supported-provider list (prefixing `mtplx/<id>`), and added an `mtplx` provider block (`http://127.0.0.1:8001/v1`) to `config-templates/caveman-agent-models.json` and the live `~/.cave/agent/models.json`, mirroring pi's adapter. Verified via `bin/smoke -m mtplx/mtplx-flash-next-optimized-speed --agent caveman` → 6/6 (100%). |
| 2026-07-07 (fixed, ollama) | **working again** | `adapters/caveman-ollama.sh` had the identical stub ("Unknown provider ollama... does not support local providers"), same root cause. Fixed the same way — added an `ollama` provider entry to `config-templates/caveman-agent-models.json` and restored the adapter's real invocation (`--provider ollama`). First smoke attempts against `qwen2.5-coder:7b`/`qwen3.5:9b`/`phi4:latest` hit a 60–90s manual-test timeout or a "does not support tools" 400 — that turned out to be **cold-load latency** (`qwen3.6:35b-a3b-coding-mxfp8` took ~26s just to JIT-load via `ollama serve`, before any inference), not a real failure; `phi4` genuinely doesn't support tool-calling over ollama and is a model limitation, unrelated to this fix. Verified via `bin/bench --agent caveman --models "qwen3.6:35b-a3b-coding-mxfp8" --cases smoke-01-edit-file,js-01-slugify-bug` → 6/6 (100%), which uses the harness's own (generous) warmup/stall budget rather than an ad hoc short timeout. **Lesson for next time:** an adapter emitting "X does not support Y" is a claim about the *installed config*, not necessarily the tool's actual capability — check the tool's own config-loading code before accepting that verdict. Separately, when manually smoke-testing a JIT-loaded local model, give it enough time to cold-load before concluding the request hung. |

## Edit mechanism

- **Format:** caveman uses a compact "caveman encoding" prompt style — compressed, token-efficient task descriptions. The model emits edits in a format the `pi` runtime applies to files in CWD. The exact edit format depends on the `--print` flag behaviour.
- **File targeting:** caveman operates on the CWD. Files are discovered autonomously; no explicit file hints are required.
- **Multi-file edits:** generally reliable on capable models. js-03 and js-04 pass on Qwen3 models. On small Gemma models (e2b, e4b), js-03 often fails — a model capability limitation rather than a caveman mechanism issue.

## Iteration / self-verify behaviour

caveman iterates through test results natively. For self-verify cases (js-05, js-06), the `pi` runtime runs the provided test suite and feeds results back to the model. On capable models, js-05 and js-06 pass at high rates (5/5 and 4/4). Self-verify performance is comparable to opencode.

Notably, caveman achieves strong self-verify results on larger models: qwen3.6-35b-a3b, qwen3-coder-30b, qwen3-coder-next, gemma-4-26b-a4b-qat all score 5/5 on js-05 and 4/4 on js-06 under caveman.

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| measured pending | measured pending | measured pending | measured pending | measured pending |

## Capability notes

- **Provider config external to adapter:** the `lmstudio` provider definition lives in `~/.cave/agent/models.json` (own config dir — see Version history above; do **not** confuse with `~/.pi/agent/models.json`, which is [pi's](pi.md) separate file). `adapters/caveman-lms.sh` now self-heals: if `~/.cave/agent/models.json` is missing or has no `lmstudio` provider, it copies `config-templates/caveman-agent-models.json` into place before invoking `caveman`. Keep the live file in sync with installed models via `bin/agents-config --agent caveman --write`.
- **Version:** `caveman --version` → `0.65.2` (checked 2026-07-07; the "Version issue" this line used to report — no version output — no longer reproduces, possibly fixed upstream alongside the package rename to `@juliusbrussee/caveman-code`).

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--provider lmstudio` | Selects the LM Studio provider defined in `~/.cave/agent/models.json` |
| `--model "$MODEL_ID"` | Sets the model key |
| `--print` | Runs non-interactively and prints the result (required for bench harness) |
| `"$(cat)"` after `--print` | Prompt piped on stdin (bench contract), consistent with `adapters/pi-lms.sh` |

## Failure modes

**Local-provider support (fixed 2026-07-07, see Version history above).** From 2026-06-28 to 2026-07-07, every case failed instantly (2s, `error(1)`) with:

```
Error: caveman adapter for LM Studio is not supported.
The installed caveman-code (npm) does not support local providers.
It only works with cloud providers (Anthropic, OpenAI, etc.) via environment variables.
```

This affected every model, not just the specific model under test that day (`qwen/qwen3-coder-next`), since the error fired before any model call. Root cause was **not** a missing capability in the tool — `@juliusbrussee/caveman-code` fully supports custom local providers via `~/.cave/agent/models.json` (same schema as pi's `models.json`); the file just didn't exist yet after caveman-code split off from the shared pi runtime, and `adapters/caveman-lms.sh` had been changed to fail fast with a since-superseded error message instead of leaving a config gap that would hang. **If this message reappears**, check `~/.cave/agent/models.json` exists and has a `providers.lmstudio` entry (`jq '.providers.lmstudio' ~/.cave/agent/models.json`) before assuming the tool itself regressed again — `bin/agents-config --agent caveman --write` will recreate it from the template.

**Infrastructure errors on partial-run models:** caveman exits with error(1) on models that weren't properly loaded (gemma-4-12b, gemma-4-31b, gemma-4-31b-qat). These are infrastructure failures.

**Compact prompt under-specification:** the caveman encoding is token-efficient but occasionally under-specifies the task for smaller models. Examples:
- gemma-4-e2b: caveman fails js-02-debounce-feature (0/4) where aider succeeds (4/completions)
- gemma-4-e2b-qat: caveman fails ts-01-groupby (0/3) where others succeed
- qwen3.5-9b: caveman hits a timeout on js-02 (0/1, 300s) where others pass

This pattern is more common on sub-8B models, suggesting the compact encoding requires more model capacity to interpret correctly.

**Lingering on self-verify (timeout with pass):** caveman occasionally stays running after completing a self-verify case, hitting the 300s timeout with a correct result. Observed on gemma-4-12b-qat js-05 (5/5, timeout) and qwen3.5-9b js-05 (5/5, no timeout but long). The edit and tests pass; caveman doesn't exit cleanly. Not a quality issue.

**js-03-multifile-cache on qwen3-coder-next (0/1):** caveman fails js-03 for qwen3-coder-next where codex passes 5/5. The multi-file cache case requires edits to two specific files; caveman's compact prompt may not communicate the second file clearly enough to this model.

## Status

**stable (re-fixed 2026-07-07, was broken 2026-06-28–2026-07-07)** — historically second-best adapter overall (87.1% across all models, pre-break data), trades blows with opencode, faster than opencode on most models. Both `lms` and `ollama` local-provider config gaps are now fixed and verified via real `bin/bench` runs: lms on `qwen/qwen3.5-9b` (6/6) and `qwen/qwen3-coder-30b` (results/20260707-072147 and the run(s) immediately after); ollama on `qwen3.6:35b-a3b-coding-mxfp8` (6/6, results/20260707-091202). Historical per-model numbers above the break predate the `caveman-code` package split and should still be broadly representative, but a fresh full sweep would confirm nothing else changed with the new package (0.65.2) vs the old pi-based runtime.

## Comparison with other adapters

caveman is the speed/quality sweet spot: faster than codex, comparable quality to opencode on large models, and more reliable than aider on multi-file cases. For models where both opencode and caveman work, caveman is often the faster choice with similar quality. The compact encoding is its distinguishing characteristic — it may explain why some models perform differently under caveman vs other adapters.
