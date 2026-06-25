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
| **Workarounds needed** | model-dependent — **shim** for qwen3-coder (edit-tool XML recovery, see Known issues); **none** for qwen3.6-35b-a3b. |
| **Last reviewed** | 2026-06-18 |

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

**Caveman shares the pi runtime:** `caveman` is also built on the pi agent runtime. If both are run concurrently in `bin/bench`, they share the same `~/.pi/agent/models.json` config. Verify they use separate config paths or run them in separate slots.

**`edit` tool can fail with qwen3-coder (nested-schema × flat XML tool calls) — observed 2026-06-25; scope corrected 2026-06-25.** pi's `edit` tool requires a nested param `edits: [{oldText, newText}]`. On a **flat-XML tool-call path**, a model emits `<parameter=NAME>` Hermes/Qwen XML that cannot encode a nested array-of-objects; the parser mangles the call: `oldText` content (with a literal `<parameter=oldText>` prefix) lands in the `edits` *string*, `newText` becomes a stray sibling key → schema validation fails (`edits.0 must be object` + additional-property `newText`). The model then self-recovers by falling back to the `write` tool (full-file rewrite), so simple cases still pass but waste round-trips and rewrite whole files.

- **It is PATH-dependent, not an intrinsic property of qwen3-coder.** ⚠️ The original handoff (from `~/src/jirafs`) called this "structural — the model CANNOT encode the nested array." A captured **bench** session transcript falsifies that for the bench's own path: via [`pi --provider lmstudio`](../../adapters/pi-lms.sh) (OpenAI-compatible, *structured* `tool_calls`), qwen3-coder-30b emitted a clean nested `edits:[{oldText,newText}]` that succeeded — no XML, no mangling, no `write` fallback (see `~/.pi/agent/sessions/--…-pi-qwen_qwen3-coder-30b-smoke-01-edit-file--`). The mangling appears only when the model is driven through a `<parameter=>` **prompt-template** path instead of structured tool_calls (the jirafs setup). So the trigger is the *client/template path*, not the model name. **Pending:** a fresh live re-confirm on the current LM Studio build (deferred — shared GPU/RAM with another model under test). Use `bin/trace-edit pi-lms qwen/qwen3-coder-30b` to capture and `bin/trace-tool-calls` to read the verdict.
- It is *not* a parameter-naming issue and no system-prompt tweak fixes it on an affected path (the model already uses the right names). Any pi tool with a nested-object-array param is exposed when a model is driven via the flat-XML template path.
- **Workaround (shim):** a `recoverXmlParameterEdits` helper added to `prepareEditArguments` in pi's `dist/core/tools/edit.js` regex-extracts oldText/newText from the mangled blob and rebuilds a valid `edits[]`. pi already ships sibling shims there for Opus/GLM JSON-string edits. Verified against the real captured payload + 5 regression cases (proper array, JSON-string, legacy flat, full XML blob, unrecoverable-left-untouched).
- **Reproducibility:** pi is a global npm install, so the patch is wiped on upgrade. The reapply script now lives **in this repo** at [`bin/pi-patch-edit-shim`](../../bin/pi-patch-edit-shim) (idempotent; `--check`). It is applied automatically before every run by all pi *and* caveman adapters ([`adapters/pi-lms.sh`](../../adapters/pi-lms.sh), `pi-mlx.sh`, `pi-ollama.sh`, [`adapters/caveman-lms.sh`](../../adapters/caveman-lms.sh), `caveman-ollama.sh`) — they call it as a fast idempotent no-op and warn (non-fatally) if it can't patch. `llmrun` points at this repo's adapters, so it inherits the shim too; the old `dotfiles/bin/pi-patch-edit-shim` is now redundant. Durable alternative: upstream PR to `@earendil-works/pi-coding-agent`.
- **Score-blindness — this failure does NOT lower the `smoke-01-edit-file` score.** Across every recorded run, pi+qwen3-coder-30b (and caveman) score `1.00` on smoke-01 *with or without* the shim, because the model self-recovers via the `write` tool and still produces a correct file. The cost is wasted round-trips and whole-file rewrites, not a failed grade. **Implication:** the grader's pass-rate cannot detect this; only the tool-call trace can. A single-edit smoke case is the wrong instrument — to observe the failure (or confirm a model is immune) you must inspect the captured tool calls for the mangled `<parameter=oldText>` blob, or use a multi-edit case where the `write` fallback is materially costlier.
- **Caveman open question — resolved by reasoning, not by score.** `caveman` shares the pi runtime, so its qwen3-coder-30b = 100% is fully consistent with the failure existing: like pi, caveman would recover via `write` and still score 1.00. A re-run will report 1.00 regardless of whether a nested `edit` was attempted. To learn whether caveman actually *exercises* a nested `edit`, inspect its tool-call trace on a real edit case — the score alone is uninformative.

## Status

**stable** — full 10-case benchmark completed 2026-06-18 (lms runtime, `qwen/qwen3.6-35b-a3b`): 36/36 points (1.00). Consistently fast — fastest agent in the field on most cases.

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

### Smoke results (2026-06-18, lms)

| Model | smoke-00-hello | smoke-01-edit-file |
|-------|:--------------:|:------------------:|
| qwen/qwen3.6-35b-a3b | 2/2 (24s) | 2/2 (7s) |
| qwen/qwen3.5-9b | 2/2 (14s) | 2/2 (6s) |
| google/gemma-4-26b-a4b-qat | 2/2 (11s) | 2/2 (14s) |
| qwen/qwen3-coder-30b | 2/2 (13s) | 2/2 (8s) |
| qwen/qwen3-coder-next | 2/2 (16s) | 2/2 (18s) |
