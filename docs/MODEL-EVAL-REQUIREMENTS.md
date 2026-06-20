# Model evaluation page — requirements

Related: [TOOL-EVAL-REQUIREMENTS.md](TOOL-EVAL-REQUIREMENTS.md) · [MODEL-RESEARCH.md](MODEL-RESEARCH.md) · [../BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md)

Each model in `models.txt` gets one evaluation page at
`docs/models/<slug>.md`, where `<slug>` is the model key with `/` replaced by
`--` (e.g. `google--gemma-4-e2b-qat.md`).

`BENCHMARK-RESULTS.md` is the **score ledger** — raw numbers, one entry per
run. A model eval page is the **reasoning layer** — observations, patterns,
and decisions that accumulate across runs and can't be derived from the CSV.
Don't duplicate the score table here; link to it or summarise only what the
numbers mean.

---

## Required sections

### Metadata
One-line block covering:
- **Model key** (exact `models.txt` entry)
- **Family / arch** — e.g. Gemma 4, MoE/dense, QAT/fp16
- **Parameter count** — total and active (for MoE)
- **Disk size** — as reported by `lms load` at time of last run
- **Added** — date first benchmarked (YYYY-MM-DD)
- **Last run** — date of most recent completed bench run

### Results summary
A brief qualitative characterisation of how this model performs overall —
not a score table (that's in `BENCHMARK-RESULTS.md`) but a sentence or two:
which adapters it works well with, how it ranks among similar-sized models,
any headline surprises.

Link to the relevant section in `BENCHMARK-RESULTS.md`.

### Failure patterns
The most analytical section. Categorise failures by cause, not just by case:

**Cross-adapter failures** — cases that fail or score poorly on *all* (or
nearly all) adapters. These are model weaknesses: capability gaps, knowledge
gaps, or context limitations. Name the likely root cause (e.g. "multi-step
shell pipeline reasoning", "cross-file symbol tracking").

**Adapter-specific failures** — cases that only fail on one or two adapters.
These are interaction effects between this model and that tool's prompt/diff
format. Note the adapter and the suspected mechanism.

**Soft failures** (WARN / partial score) — cases where the model partially
completes the task. Often more informative than a hard FAIL because they show
*where* it stops.

### Timing observations
- Typical wall-clock range per adapter (fast/slow cases)
- Whether the tool lingers after completing the edit (inflated `seconds`,
  status=timeout with a correct result)
- Any cases where the model is notably slow or fast relative to its size class

### Better alternatives
When is this model *not* the right pick? Name specific alternatives at similar or smaller size and the conditions under which they win:

- Which models at the same or lower parameter count outperform this one, and on what task types?
- Which quantisation variant or family member is the better default?
- If this model has a niche where it clearly leads (speed, a specific adapter, a task type), name it.

Keep it concrete — one sentence per alternative. This section makes the eval page actionable for someone choosing between models.

### Known issues
Concrete, reproducible problems observed across runs:

- Context-length problems (prompt truncation, mid-generation cut-off)
- Template/format problems (model ignores diff format, produces wrong edit syntax)
- Quantisation artefacts (hallucinated symbols, unstable outputs at low bit-width)
- Tool-specific integration issues (provider routing, model-key matching)

Each issue should note: *what happens*, *which adapter(s)*, *how often* (every
run / intermittent), and a suggested fix or workaround if known.

### Status
One of: **keep** · **rerun** · **update** · **remove**

| Status | Meaning |
|--------|---------|
| keep | Stable results; no action needed until a new release or changed case set |
| rerun | Results are suspect (small sample, known transient issue, harness bug during run); schedule a re-run |
| update | A new model release or quant variant is available; re-download and re-run |
| remove | No longer worth benchmarking (consistently last-place at its size, better alternative exists, download no longer available) |

Include a one-line rationale and, for **rerun** / **update** / **remove**, a
suggested trigger (e.g. "rerun after `bash-01` case is revised",
"update when gemma-4-e2b-q8 is available in LM Studio").

---

## Optional sections

### Observations across runs
If the model has been benchmarked more than once (different harness versions,
different case sets, or repeated trials), note how results changed and why.
Append new entries with a date heading rather than rewriting old ones — the
history is informative.

### Comparison within family / size class
When several models of the same size are in the bench suite
(e.g. `gemma-4-e2b-qat` vs `gemma-4-e2b`), a short note on which is faster /
more accurate and whether the difference is worth the extra memory.

### Suggested experiment
A concrete next test that would be informative: e.g. "run with `--trials 3`
to check stability", "test at higher context length", "try codex with file
hints enabled".

---

## Writing style

- Write observations, not scores. Scores live in the CSV and
  `BENCHMARK-RESULTS.md`.
- Be specific: name the case, the adapter, the timing, the failure mode. Vague
  notes ("performs OK on simple tasks") decay into noise.
- Use past tense for findings, present tense for standing issues.
- Update **Last run** and **Status** every time new bench data arrives.
- Keep each section short. The eval page is a reference, not an essay.
