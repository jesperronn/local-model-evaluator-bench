# Benchmark results

Local LM Studio models as code editors, scored by automated test pass-rate
across CLI tools. Cases: `js-01-slugify-bug`, `js-02-debounce-feature`,
`ts-01-groupby`, `bash-01-topwords` (see `cases/`). Tools: aider, opencode,
codex, caveman. (`hermes` excluded — runs in an isolated container workspace;
see `adapters/hermes.sh`.)

Score = fraction of a case's hidden tests that pass after the tool edits the
code. Each cell below is `passed-tests / total-tests` summed over the 4 cases
(max 16 sub-tests: slugify 4 + debounce 4 + groupBy 3 + topwords 4... = 15).

Models tested in ascending memory order:

| # | Model | Size | Status |
|---|-------|------|--------|
| 1 | qwen/qwen3.5-9b | 5.98 GB | ✅ done |
| 2 | google/gemma-4-e4b | 6.33 GB | ✅ done |
| 3 | google/gemma-4-12b-qat | 7.15 GB | pending |
| 4 | google/gemma-4-12b | 7.56 GB | pending |
| 5 | google/gemma-4-26b-a4b-qat | 15.64 GB | pending |
| 6 | qwen/qwen3-coder-30b | 17.19 GB | pending |
| 7 | qwen/qwen3.6-35b-a3b | 22.07 GB | pending |
| 8 | google/gemma-4-31b | 28.85 GB | pending |

---

## 1. qwen/qwen3.5-9b (5.98 GB)

Score = passing sub-tests across the 4 real cases (max **15**).

| Tool | slugify /4 | debounce /4 | groupBy /3 | topwords /4 | **Total** | Notes |
|------|:---:|:---:|:---:|:---:|:---:|-------|
| aider    | 2 | 4 | 3 | 4 | **13/15** | fast (17–29s); left `slugify.js` unedited (2/4 = original) |
| opencode | 4 | 4 | 3 | 4 | **15/15** | clean except 1 lingering-exit on topwords |
| codex    | 4 | 4 | 3 | 4 | **15/15** | correct but 2 lingering-exits (240s) — didn't terminate |
| caveman  | 4 | 4 | 3 | 4 | **15/15** | clean, no timeouts (48–148s) |

**Verdict:** qwen3.5-9b is a strong local coding model — 3 of 4 tools scored a
perfect 15/15. Solid first baseline.

**Suggestions to improve:**
- **aider**: pass the case's target files (`meta.edit_files`) as args so the
  model's edit reliably applies — with no file in the chat, aider sometimes
  leaves the source untouched (the slugify miss here). Highest-value fix.
- **codex / opencode**: they finish the edit quickly but the CLI lingers until
  the 240s timeout. Investigate a cleaner non-interactive exit (e.g. codex
  `--output-last-message` / a turn cap) so wall-clock and the timeout column
  reflect real work. Scores are unaffected, but it wastes minutes per case.
- **harness**: exclude `smoke-00-hello` from benchmark runs (done from model 2
  onward) — it's a connectivity check, not a quality case.

## 2. google/gemma-4-e4b (6.33 GB)

| Tool | slugify /4 | debounce /4 | groupBy /3 | topwords /4 | **Total** | Notes |
|------|:---:|:---:|:---:|:---:|:---:|-------|
| caveman  | 4 | 4 | 3 | 1 | **12/15** | most robust with this small model; clean |
| opencode | 4 | 4 | 3 | 1 | **12/15** | clean, no timeouts |
| aider    | 4 | 4 | 3 | 0 | **11/15** | only the bash case failed |
| codex    | 4 | 0 | 0 | 1 | **5/15**  | left debounce & groupBy as **unedited stubs** |

**Verdict:** a 4B-class model is usable for small JS/TS edits but unreliable on
the bash task (topwords 0–1/4 everywhere — sorting + tie-break + n-limit is too
much for it). Tool choice matters far more at this size than at 9B.

**Suggestions to improve:**
- **codex + weak models**: codex relies on the model driving its `apply_patch`
  tool; gemma-4-e4b couldn't, so codex made **no edit at all** on 2 cases (files
  left as stubs) and logged a models-endpoint decode error. Practical guidance:
  codex needs a ≥~9B tool-capable model — flag/skip it below that, or add a
  fallback "rewrite whole file" path for weak models.
- **caveman / opencode** degrade most gracefully on small models — prefer them
  when testing sub-9B models.
- The **topwords** case is a strong discriminator at the low end; keep it.

