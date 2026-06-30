# Card specification — the single source of truth for model / tool / runtime cards

> **This file is canonical.** It merges the former `docs/templates/*.md` and
> `docs/MODEL-EVAL-REQUIREMENTS.md` / `docs/TOOL-EVAL-REQUIREMENTS.md` into one
> spec so there is only one place to drift from. Those files now redirect here.
>
> It defines, per card type: the **required** sections (every card must have
> them, in this order), the **optional** sections, and a copy-paste **skeleton**.
> The companion regression test is [QUESTION-SUITE.md](QUESTION-SUITE.md)
> sections C (model), D (tool), E (runtime) — each question maps to a section
> below. A card that can't answer a question = a missing/empty section to fix.

## Governing principles

1. **Accuracy and speed are co-equal; speed breaks ties.** Every Quick verdict
   carries the rule: *when accuracy is equal, prefer the faster one.* The Speed
   value must always be filled — `"unknown"` is not acceptable for an evaluated
   subject.
2. **Progressive disclosure.** Quick verdict first (the at-a-glance answer), then
   Metadata, then detail. A reader gets the decision in the first table.
3. **Measured vs inferred.** Accuracy and speed are measured numbers with a run
   ID, never guessed. Mark anything inferred as such.
4. **Consistency across card types.** The same question is answered the same way
   on every card of a type. This spec is what makes that testable.

---

## Model card — `docs/models/<key>.md`

### Required sections (in order)

| # | Section | Must answer | QUESTION-SUITE |
|---|---------|-------------|----------------|
| 1 | **Quick verdict** | accuracy, speed (avg), best adapter, recommended-for, status (keep/watch/drop) — as a table, with the co-equal rule restated | Q37–41 |
| 2 | **Metadata** | model key, family/arch, param count (total+active), quantization, disk size, context window, dates (Added / Last run + run ID / Doc updated) | Q42–48 |
| 3 | **Results summary** | per-adapter accuracy + speed + runtime table; working-adapters total; overall-incl-broken total | Q49–50 |
| 4 | **Timing observations** | fastest adapter, slowest adapter, slow cases, runtime note — **in absolute seconds** | Q51 |
| 5 | **Failure patterns** | repeatable failures with cause, or explicitly "none" | Q52 |
| 6 | **Better alternatives** | is there a strictly-better model to recommend (any family) for some/all of this model's use? If this is the best, say so. | Q53 |
| 7 | **Status** | keep / watch / drop + one-sentence rationale; cross-link comparable siblings | Q41 |

### Optional sections

- **Comparison within family** — sibling accuracy-vs-speed table; which to prefer when.
- **Observations across runs** — dated changelog, newest first, with run ID.
  *Note: only meaningful for full runs; brief/smoke tests make this noisy. A
  separate run-log document may be split out later (deferred).*

### Skeleton

```markdown
# <model-key>

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | <e.g. 100% across working adapters> |
| **Speed (avg)** | <e.g. ~48s per case (lms, 3B active)> |
| **Best adapter** | <e.g. codex — fastest; cline — most reliable> |
| **Recommended for** | <e.g. general agentic coding, multi-file edits> |
| **Status** | <keep / watch / drop> |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | <exact id used in adapters/bench> |
| **Family / arch** | <e.g. Qwen3.6, MoE> |
| **Parameter count** | <e.g. 35B total, 3B active> |
| **Quantization** | <e.g. GGUF Q4_K_M, MLX 6-bit> |
| **Disk size** | <e.g. 22.07 GB> |
| **Context window** | <e.g. 256k native; 65536 loaded for bench> |
| **Added** | <YYYY-MM-DD> |
| **Last run** | <YYYY-MM-DD (run ID)> |
| **Doc updated** | <YYYY-MM-DD> |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|

**Working adapters total:** <e.g. 9/11>
**Overall (incl. broken adapters):** <e.g. 366/406 (90%)>

## Timing observations
## Failure patterns
## Better alternatives
## Status
<!-- optional: ## Comparison within family / ## Observations across runs -->
```

---

## Tool card — `docs/tools/<name>.md`

### Required sections (in order)

| # | Section | Must answer | QUESTION-SUITE |
|---|---------|-------------|----------------|
| 1 | **Quick verdict** | accuracy (on which model), speed (avg), best model, recommended-for, status (stable/experimental/broken) — table + co-equal rule | Q55–59 |
| 2 | **Metadata** | CLI command, version, adapter script (linked), how it connects, last reviewed | Q60–63 |
| 3 | **Edit mechanism** | edit format, file targeting, multi-file support | Q64–66 |
| 4 | **Iteration / self-verify behaviour** | does it loop on test failure, or single-pass? (standalone section) | Q67 |
| 5 | **Results by model** | accuracy + speed + runtime table, sorted accuracy desc then speed asc | Q68 |
| 6 | **Capability notes** | critical-path strengths/weaknesses by area — explicitly flag if **tool-editing is dubious** or a category (e.g. **bash editing**) is stuck, since these gate real use. One line per concern, or "no known blockers." | Q70b (new) |
| 7 | **Adapter flags and their rationale** | each flag + why (table) | Q69 |
| 8 | **Failure modes** | repeatable failures with root cause | Q70 |
| 9 | **Status** | stable / experimental / broken + rationale; cross-link models/runtimes | Q59 |

### Optional sections

- **Better alternatives** — is another tool strictly better for this workload?
- **Comparison with other adapters** — cross-tool note.
- **Observations across runs/versions** — dated changelog, newest first.
  *(Same noisiness caveat as model cards.)*

> **Dropped from the old templates:** the full per-case breakdown table (too much
> detail for routine cards). The required **Capability notes** section captures
> the signal that mattered — which areas are blocked — without the full table.

### Skeleton

```markdown
# <Tool name>

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | <e.g. 100% on qwen3.6-35b-a3b (lms)> |
| **Speed (avg)** | <e.g. ~54s per case> |
| **Best model** | <e.g. qwen/qwen3.6-35b-a3b> |
| **Recommended for** | <e.g. autonomous multi-file edits, self-verify loops> |
| **Status** | <stable / experimental / broken> |

> Rule: when two tools have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **CLI command** | <e.g. `aider`> |
| **Version** | <e.g. 0.86.2> |
| **Adapter script** | [`adapters/<name>.sh`](../../adapters/<name>.sh) |
| **How it connects** | <e.g. OpenAI-compat via `--openai-api-base`> |
| **Last reviewed** | <YYYY-MM-DD> |

## Edit mechanism
- **Format:** <tool calls / search-replace / unified diff / whole-file>
- **File targeting:** <autonomous / explicit path / git-diff>
- **Multi-file edits:** <native / limited / none>

## Iteration / self-verify behaviour
<loops on test failure, or single-pass?>

## Results by model

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|

## Capability notes
<critical-path flags: tool-editing reliability, bash/category blocks, or "no known blockers">

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|

## Failure modes
## Status
<!-- optional: ## Better alternatives / ## Comparison with other adapters / ## Observations across versions -->
```

---

## Runtime card — `docs/runtimes/<name>.md`

> **Status: not yet created.** No `docs/runtimes/` directory exists. Runtime
> behaviour currently lives inline in model cards (e.g. the MLX-vs-GGUF speed
> note). This spec is ready for when runtime cards are written; until then,
> QUESTION-SUITE section E is aspirational.

### Required sections (in order)

| # | Section | Must answer | QUESTION-SUITE |
|---|---------|-------------|----------------|
| 1 | **Quick verdict** | accuracy impact vs baseline, speed vs baseline (×lms), best model class, recommended-for, status | Q71–73 |
| 2 | **Metadata** | CLI/binary, version, API compatibility, base URL, model formats, platform, last reviewed | Q74 |
| 3 | **Connection setup** | env vars, base-URL quirks (e.g. /v1 stripping), parameter passthrough | Q75 |
| 4 | **Performance characteristics** | per model-class accuracy + speed-vs-baseline, with numbers | Q76 |
| 5 | **Supported model formats** | GGUF / MLX / bf16 / AWQ — ✅/❌ + notes | Q77 |
| 6 | **Adapter compatibility** | per-adapter ✅/❌ + note | Q78 |
| 7 | **Status** | primary / secondary / experimental / not-installed + rationale | Q73 |

(See the former `docs/templates/runtime-card-template.md` content folded above;
skeleton matches the model/tool pattern.)

---

## Changelog

- **2026-06-30** — Created by merging `docs/templates/*.md` +
  `docs/{MODEL,TOOL}-EVAL-REQUIREMENTS.md`. Decisions: Quick verdict is
  **mandatory** on all cards (backfill via the smaller-model card-sweep, tooling
  TBD); REQUIREMENTS naming wins where it disagreed with templates (standalone
  *Iteration / self-verify*, *Adapter flags and their rationale*); model cards
  keep both *Better alternatives* (required) and *Comparison within family*
  (optional); full per-case breakdown dropped in favour of required
  *Capability notes*; *Suggested experiment* dropped.
