# pi

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | pi (coding agent) |
| **CLI command** | `pi` |
| **npm package** | `@earendil-works/pi-coding-agent` |
| **Version** | latest |
| **Adapter script** | [`adapters/pi-lms.sh`](../../adapters/pi-lms.sh) |
| **How it connects** | `--provider lmstudio` selects the built-in LM Studio provider (localhost:1234/v1). Model passed via `--model`. |
| **Runtime model discovery** | **no** — this is `@earendil-works/pi-coding-agent`, not [`oh-my-pi`](https://github.com/can1357/oh-my-pi) (a different, similarly-named tool that *does* have native Ollama/llama.cpp/LM Studio discovery — see [docs/tools/omp.md](omp.md) for its full card). This repo's `pi` needs its model list pre-populated in `~/.pi/agent/models.json`, which `bin/agents-config` keeps in sync with `lms ls`/`ollama list`. [`config-templates/pi-agent-models.json`](../../config-templates/pi-agent-models.json) declares all three provider blocks (`lmstudio`, `ollama`, `omlx`), matching caveman's schema (see [caveman.md](caveman.md)), so `bin/agents-config` keeps all three in sync, not just `lmstudio`. The bench always pins an explicit `--model` per trial anyway, so discovery wouldn't remove that step even if this `pi` had it. |
| **Workarounds needed** | model-dependent — **shim** for qwen3-coder (edit-tool XML recovery, see Known issues); **none** for qwen3.6-35b-a3b. |
| **Last reviewed** | 2026-07-05 |
| **Recommended for** | Large models (30B+) AND small models (3.8B–9B) — only validated agent for small models |

## Edit mechanism

- **Format:** pi uses an agentic coding loop with tool calls. The `-p` flag runs it headlessly with a prompt string; without `-p` it starts an interactive TUI.
- **File targeting:** autonomous — pi discovers and edits files in CWD via its own toolset.
- **Multi-file edits:** tool-call architecture supports multi-file edits natively.

## Iteration / self-verify behaviour

pi is an autonomous agent loop. For self-verify cases (js-05, js-06), pi can run tests and iterate on failures. The `-p` flag feeds the full prompt non-interactively; the loop runs until the task is complete or a turn limit is hit.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--provider lmstudio` | Selects LM Studio as the model backend |
| `--model "$MODEL_ID"` | Overrides the model at runtime |
| `-p "$(cat)"` | Non-interactive prompt delivery (headless mode) |

## Known issues

**Caveman is a separate package (corrected 2026-07-07):** `caveman` (`@juliusbrussee/caveman-code`) used to share pi's runtime and `~/.pi/agent/models.json` config, but split into its own package with its own config dir (`~/.cave/agent/models.json`) around 2026-06-28. They no longer share config, so no conflict risk running both concurrently in `bin/bench` — but this also means caveman's own config can silently drift out of sync unless `bin/agents-config --agent caveman` is run alongside pi's sync. See [caveman.md](caveman.md#version-history-last-working--broken--fixed) for the outage this caused and the fix.

**`edit` tool can fail with qwen3-coder (nested-schema × flat XML tool calls) — observed 2026-06-25; scope corrected 2026-06-25.** pi's `edit` tool requires a nested param `edits: [{oldText, newText}]`. On a **flat-XML tool-call path**, a model emits `<parameter=NAME>` Hermes/Qwen XML that cannot encode a nested array-of-objects; the parser mangles the call: `oldText` content (with a literal `<parameter=oldText>` prefix) lands in the `edits` *string*, `newText` becomes a stray sibling key → schema validation fails (`edits.0 must be object` + additional-property `newText`). The model then self-recovers by falling back to the `write` tool (full-file rewrite), so simple cases still pass but waste round-trips and rewrite whole files.

- **It is PATH-dependent, not an intrinsic property of qwen3-coder.** ⚠️ The original handoff (from `~/src/jirafs`) called this "structural — the model CANNOT encode the nested array." A captured **bench** session transcript falsifies that for the bench's own path: via [`pi --provider lmstudio`](../../adapters/pi-lms.sh) (OpenAI-compatible, *structured* `tool_calls`), qwen3-coder-30b emitted a clean nested `edits:[{oldText,newText}]` that succeeded — no XML, no mangling, no `write` fallback (see `~/.pi/agent/sessions/--…-pi-qwen_qwen3-coder-30b-smoke-01-edit-file--`). The mangling appears only when the model is driven through a `<parameter=>` **prompt-template** path instead of structured tool_calls (the jirafs setup). So the trigger is the *client/template path*, not the model name. **Pending:** a fresh live re-confirm on the current LM Studio build (deferred — shared GPU/RAM with another model under test). Use `bin/trace-edit pi-lms qwen/qwen3-coder-30b` to capture and `bin/trace-tool-calls` to read the verdict.
- It is *not* a parameter-naming issue and no system-prompt tweak fixes it on an affected path (the model already uses the right names). Any pi tool with a nested-object-array param is exposed when a model is driven via the flat-XML template path.
- **Workaround (shim):** a `recoverXmlParameterEdits` helper added to `prepareEditArguments` in pi's `dist/core/tools/edit.js` regex-extracts oldText/newText from the mangled blob and rebuilds a valid `edits[]`. pi already ships sibling shims there for Opus/GLM JSON-string edits. Verified against the real captured payload + 5 regression cases (proper array, JSON-string, legacy flat, full XML blob, unrecoverable-left-untouched).
- **Reproducibility:** pi is a global npm install, so the patch is wiped on upgrade. The reapply script now lives **in this repo** at [`bin/pi-patch-edit-shim`](../../bin/pi-patch-edit-shim) (idempotent; `--check`). It is applied automatically before every run by all pi *and* caveman adapters ([`adapters/pi-lms.sh`](../../adapters/pi-lms.sh), `pi-mlx.sh`, `pi-ollama.sh`, [`adapters/caveman-lms.sh`](../../adapters/caveman-lms.sh), `caveman-ollama.sh`) — they call it as a fast idempotent no-op and warn (non-fatally) if it can't patch. `llmrun` points at this repo's adapters, so it inherits the shim too; the old `dotfiles/bin/pi-patch-edit-shim` is now redundant. Durable alternative: upstream PR to `@earendil-works/pi-coding-agent`.
- **Score-blindness — this failure does NOT lower the `smoke-01-edit-file` score.** Across every recorded run, pi+qwen3-coder-30b (and caveman) score `1.00` on smoke-01 *with or without* the shim, because the model self-recovers via the `write` tool and still produces a correct file. The cost is wasted round-trips and whole-file rewrites, not a failed grade. **Implication:** the grader's pass-rate cannot detect this; only the tool-call trace can. A single-edit smoke case is the wrong instrument — to observe the failure (or confirm a model is immune) you must inspect the captured tool calls for the mangled `<parameter=oldText>` blob, or use a multi-edit case where the `write` fallback is materially costlier.
- **Caveman open question — resolved by reasoning, not by score.** `caveman` shares the pi runtime, so its qwen3-coder-30b = 100% is fully consistent with the failure existing: like pi, caveman would recover via `write` and still score 1.00. A re-run will report 1.00 regardless of whether a nested `edit` was attempted. To learn whether caveman actually *exercises* a nested `edit`, inspect its tool-call trace on a real edit case — the score alone is uninformative.

## Status

**stable** — full 10-case benchmark completed 2026-06-18 (lms runtime, `qwen/qwen3.6-35b-a3b`): 36/36 points (1.00). Consistently fast — fastest agent in the field on most cases.

## Small Model Evaluation (3.8B–9B parameters)

**New (2026-07-05):** pi is now the **only validated agent for small model evaluation** after fair-comparison testing across 4 candidate agents.

### Why pi for small models?

Fair comparison testing (2026-07-05) evaluated shai, qwen, vibe, and pi using identical prompts and measurement methodology:

- **pi:** Response length varies 3.3K → 512K chars (actual model inference ✅)
- **shai:** Always 3,611 chars, 38ms (cached response, not calling model ❌)
- **qwen:** Always 442 chars, fixed output (truncation/error ❌)
- **vibe:** Always 244 chars, fixed output (truncation/error ❌)

**Selection:** pi is the only agent showing real model inference behavior. Safe for benchmarking small models with valid metrics.

### Configuration for small models

```bash
# Updated defaults (2026-07-05, see config.sh):
export PREFERRED_MODEL_ID="qwen2.5-coder-7b"  # 7B, balanced speed/quality
DEFAULT_ADAPTERS="pi"                          # pi only for small models

# Run small model benchmark:
bin/bench --models qwen2.5-coder-7b,phi4:latest --trials 3
```

### Tested small models

| Model | Size | Inference Time | Recommendation |
|-------|------|-----------------|-----------------|
| qwen2.5-coder-7b | 7B | 2.9s avg | ✅ Recommended — balanced |
| phi4 | 3.8B | 1.0s avg | ✅ Alternative — fastest |
| qwen3.5 | 9B | 6.4s avg | ✅ Alternative — best quality |

See [`docs/SMALL-MODEL-EVALUATION.md`](../SMALL-MODEL-EVALUATION.md) for full details on small model benchmarking, methodology, and results.

### Full benchmark results (2026-06-18, lms, run `20260618-190652`)

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| bash-01-topwords | 4/4 (1.00) | 49s | ok |
| js-01-slugify-bug | 4/4 (1.00) | 18s | ok |
| js-02-debounce-feature | 4/4 (1.00) | 19s | ok |
| js-03-multifile-cache | 5/5 (1.00) | 35s | ok |
| js-04-multifile-rename | 3/3 (1.00) | 26s | ok |
| js-05-multiselect-filter | 5/5 (1.00) | 55s | ok |
| js-06-lint-and-test | 4/4 (1.00) | 68s | ok |
| smoke-00-hello | 2/2 (1.00) | 8s | ok |
| smoke-01-edit-file | 2/2 (1.00) | 6s | ok |
| ts-01-groupby | 3/3 (1.00) | 19s | ok |
| **Total** | **36/36 (1.00)** | | |

### Full benchmark results (2026-06-18, lms, run `20260618-215910`) — `google/gemma-4-26b-a4b-qat`

Run concurrently with a hermes bench on the same model; timeouts reflect slot contention, not correctness failures — all cases passed.

| Case | Score | Time | Status |
|------|------:|-----:|--------|
| bash-01-topwords | 4/4 (1.00) | 300s | timeout† |
| js-01-slugify-bug | 4/4 (1.00) | 129s | ok |
| js-02-debounce-feature | 4/4 (1.00) | 180s | ok |
| js-03-multifile-cache | 5/5 (1.00) | 187s | ok |
| js-04-multifile-rename | 3/3 (1.00) | 79s | ok |
| js-05-multiselect-filter | 5/5 (1.00) | 200s | ok |
| js-06-lint-and-test | 4/4 (1.00) | 300s | timeout† |
| smoke-00-hello | 2/2 (1.00) | 38s | ok |
| smoke-01-edit-file | 2/2 (1.00) | 27s | ok |
| smoke-02-numbers | 2/2 (1.00) | 39s | ok |
| ts-01-groupby | 3/3 (1.00) | 300s | timeout† |
| **Total** | **38/38 (1.00)** | | |

† Completed within the timeout window (all assertions pass); 300s recorded because the adapter finished at the limit due to parallel slot contention.

### Full sweep results (2026-06-29, lms, run `20260629-*`)

| Model | Score | Notes |
|-------|-------|-------|
| qwen/qwen3.6-35b-a3b | 38/38 (100%) | |
| qwen/qwen3.5-9b | 35/38 (92%) | |
| devstral-small-2-2512 | 34/38 (89%) | |
| google/gemma-4-26b-a4b-qat | 38/38 (100%) | |
| qwen/qwen3.6-27b | not run | — |
| zai-org/glm-4.7-flash | 12/32 (37%) | Timeout floor |
| qwen/qwen3-coder-30b | 37/38 (97%) | bash-01 3/4 |

### Stale-refresh sweep (2026-07-07, lms, 12-case set, runs `20260707-*`)

Re-ran the full 7-model rotation plus a one-off big-model check to clear stale/missing/failed `pi` combos.

| Model | Score | Med speed | Notes |
|-------|-------|-----------|-------|
| qwen/qwen3.6-27b | 44/44 (100%) | 95.1s | first pi run for this model — clean |
| qwen/qwen3-coder-30b | 44/44 (100%) | 51.0s | up from 97% on 2026-06-29 (bash-01 3/4 that run) |
| google/gemma-4-26b-a4b-qat | 44/44 (100%) | 71.5s | confirms 2026-06-29 100% after model re-download |
| **qwen/qwen3-coder-next** (one-off, 80B MoE) | 44/44 (100%) | **33.4s** | fastest full-clean pi run recorded in this harness; see [qwen--qwen3-coder-next.md](../models/qwen--qwen3-coder-next.md) |
| zai-org/glm-4.7-flash | 9/38 (23.7%) | 136.5s | re-download resolved to a different variant (MLX-6bit, not the GGUF this model's card was based on); most failures are `stall` status, not `timeout` — see [zai-org--glm-4.7-flash.md](../models/zai-org--glm-4.7-flash.md) |

Notably, `qwen3-coder-next` (an 80B MoE excluded from the default nightly rotation for its 45GB footprint) beat every other model on speed under pi while matching everyone else's 100% accuracy — the exclusion is a resource-budget call, not an accuracy or reliability one.

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (24s) | 2/2 (7s) |
| qwen/qwen3.5-9b | 2/2 (14s) | 2/2 (6s) |
| google/gemma-4-26b-a4b-qat | 2/2 (11s) | 2/2 (14s) |
| qwen/qwen3-coder-30b | 2/2 (13s) | 2/2 (8s) |
