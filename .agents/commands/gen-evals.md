# gen-evals — generate or update model and tool eval pages

Run `bin/gen-evals $ARGUMENTS` to collect the context bundle, then generate
or update every model eval page (`docs/models/<slug>.md`) and every tool eval
page (`docs/tools/<name>.md`) according to the requirements below.

---

## Step 1 — collect data

```bash
bin/gen-evals $ARGUMENTS
```

If `$ARGUMENTS` is empty, this uses the latest results run. If it is `--all`,
it merges all runs (latest per adapter+model+case wins). A specific CSV path
can also be passed. Read the output in full before proceeding.

---

## Step 2 — analyse the CSV

Before writing any file, build an analytical picture from the raw data.

### Per-model analysis

For each distinct model in the CSV:

1. **Score by adapter.** For each `(adapter, model)` pair, sum `pass` and
   `total` across all cases. Record `pass/total` and overall `score%`.

2. **Identify cross-adapter failures.** A case is a *cross-adapter failure*
   if it scores 0 (or WARN, i.e. partial) on **all** adapters for this model.
   This is a model weakness — the model likely cannot solve the underlying
   task regardless of tooling.

3. **Identify adapter-specific failures.** A case that fails on one adapter
   but passes on others is an *interaction effect* — suspect the adapter's
   edit format or prompt style, not the model's capability.

4. **Timing.** For each `(adapter, model)`, compute the range of `seconds`
   across cases. Note:
   - Cases with `status=timeout` where `pass>0` → tool lingered after a
     correct edit (inflated timing, not a real failure).
   - Cases with `status=timeout` where `pass=0` → genuine timeout (model too
     slow or adapter hung).
   - Compare median timing to other models of similar size.

5. **Soft failures (WARN).** Cases where `0 < pass < total`. These often
   reveal *where* the model stopped — note which sub-tests passed.

### Per-adapter analysis

For each distinct adapter in the CSV:

1. **Score across models.** Sum `pass/total` across all models and cases.

2. **Format failures.** Cases where `pass=0` consistently across many models
   (not just weak models). Suspect the adapter's edit format is incompatible
   with a model class, or the adapter lacks a required capability (e.g.
   multi-file, self-verify loop).

3. **Lingering pattern.** Count how often `status=timeout` with `pass>0`.
   If frequent, note it — the adapter doesn't exit cleanly after finishing.

4. **Self-verify cases** (`js-05-multiselect-filter`, `js-06-lint-and-test`).
   These require the tool to run tests and iterate. Score on these relative
   to other adapters reveals iteration capability.

---

## Step 3 — write model eval pages

For each model, write or update `docs/models/<slug>.md` where `<slug>` is
the model key with `/` replaced by `--`
(e.g. `google/gemma-4-e2b-qat` → `google--gemma-4-e2b-qat.md`).

Follow `docs/MODEL-EVAL-REQUIREMENTS.md` exactly for section names and content.

**Updating an existing page:** preserve all prior observations in
`### Observations across runs` (append a new dated entry, never delete old
ones). Update the score summary, failure patterns, timing, and status to
reflect the new data.

**Creating a new page:** fill all required sections. Use `<!-- TODO -->` as
a placeholder only for fields that cannot be determined from the CSV alone
(e.g. exact disk size if not in the data). Do not leave sections empty.

Key rules:
- The **Failure patterns** section is the most valuable. Be specific: name
  the case, the adapter, the score, and the likely cause. Don't write
  "performs poorly on multi-file tasks" — write "js-04-multifile-rename
  fails on all adapters (0/1 each): the model likely produces an inconsistent
  rename — the ESM import fails to load when only one file is updated."
- **Status** must be one of: keep / rerun / update / remove. Include a
  one-line rationale.
- **Do not** reproduce the full score table from `BENCHMARK-RESULTS.md`.
  Summarise in prose or a minimal table showing only noteworthy cells.

---

## Step 4 — write tool eval pages

For each adapter, write or update `docs/tools/<name>.md` where `<name>`
matches the adapter filename (e.g. `aider.md`, `opencode.md`, `codex.md`).

Follow `docs/TOOL-EVAL-REQUIREMENTS.md` exactly.

**Edit mechanism** — read the adapter script carefully:
- What flags does it pass? Do they imply a specific edit format?
- Does it pass file paths, or does the model have to discover them?
- Does it support iteration (multiple turns)?

**Failure modes** — from the analysis in Step 2:
- Note adapter-specific failures that appear across many models.
- Distinguish tool bugs from model-capability issues.
- For lingering/timeout patterns, note the frequency and which cases trigger it.

**Adapter flags** — document every non-default flag in the script with a
one-line rationale. Read the adapter script comments; they often explain the
why already.

**Status** must be one of: stable / needs-tuning / broken / under-evaluation /
retired.

---

## Step 5 — create missing directories

Before writing files:
```bash
mkdir -p docs/models docs/tools
```

---

## Constraints

- Write observations, not scores. Scores live in `BENCHMARK-RESULTS.md`.
- Be specific. Vague notes decay into noise.
- The **smoke-00-hello** case is a connectivity check only — exclude it from
  quality analysis and failure patterns.
- If the CSV has `trials > 1`, treat the scores as medians and note any
  `status` fields containing `|` (e.g. `ok|timeout`) as evidence of
  instability.
- When done, print a brief summary: which files were created, which were
  updated, and any fields left as `<!-- TODO -->` that need manual input.
