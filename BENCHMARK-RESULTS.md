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
| 3 | google/gemma-4-12b-qat | 7.15 GB | ✅ done |
| 4 | google/gemma-4-12b | 7.56 GB | ⚠️ broken template |
| 5 | google/gemma-4-26b-a4b-qat | 15.64 GB | ✅ done |
| 6 | qwen/qwen3-coder-30b | 17.19 GB | ✅ done |
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

## 3. google/gemma-4-12b-qat (7.15 GB)

Scores below use a **600s** timeout (the initial 240s run produced false
failures — this QAT model is slow, many runs took 170–480s). caveman/codex from
the 240s run, aider/opencode from the 600s re-run.

| Tool | slugify /4 | debounce /4 | groupBy /3 | topwords /4 | **Total** | Notes |
|------|:---:|:---:|:---:|:---:|:---:|-------|
| caveman  | 4 | 4 | 3 | 4 | **15/15** | clean |
| codex    | 4 | 4 | 3 | 4 | **15/15** | fastest here (80–157s) |
| opencode | 4 | 4 | 3 | 4 | **15/15** | correct but slow (207–478s) |
| aider    | 2 | 0 | 3 | 4 | **9/15**  | debounce **hangs past 600s**; slugify 2/4 again |

**Verdict:** gemma-4-12b-qat is a capable coding model (three tools at 15/15) but
**slow** due to QAT quantization. codex — which failed at 4B — is excellent here,
confirming it just needs a tool-capable model.

**Suggestions to improve:**
- **Timeout is a first-class variable.** At 240s this model looked far worse
  than it is. Slow/quantized models need ≥600s, and a tool killed mid-edit can
  leave a half-written file that *breaks test collection* (opencode's groupBy
  scored 0/1 — only 1 of 3 tests even loaded). Benchmark uses 600s from here on.
- **aider** is the weak link on gemma models: it hung on debounce past 600s
  (likely a reflect/retry loop) and repeatedly nails only 2/4 slugify cases.
  Worth trying aider's `--no-stream`/edit-format settings, or a per-tool
  hang-watchdog, for these models.

## 4. google/gemma-4-12b (7.56 GB) — ⚠️ broken prompt template

**This model is mis-configured in LM Studio**, not a tool failure. caveman and
opencode both abort with:

> `Error rendering prompt with jinja template: "Cannot call something that is
> not a function: got UndefinedValue"` … *"usually an issue with the model's
> prompt template."*

| Tool | slugify /4 | debounce /4 | groupBy /3 | topwords /4 | **Total** | Notes |
|------|:---:|:---:|:---:|:---:|:---:|-------|
| aider    | 2 | 4 | 3 | 4 | **13/15** | survived the template bug (different request path) |
| caveman  | – | – | – | – | **template error** | jinja render failure, no edit |
| opencode | – | – | – | – | **template error** | jinja render failure, no edit |
| codex    | – | – | – | – | **errored** | bailed on models endpoint / template |

**Verdict:** not a usable comparison — the GGUF's embedded chat template is
broken. The QAT sibling (#3) works fine, so this is variant-specific.

**Suggestions to improve:**
- **Fix the model, not the harness:** re-download the `lmstudio-community`
  build of gemma-4-12b (fixed templates) or override the Prompt Template in LM
  Studio → My Models → model settings. Then re-run model #4.
- **Harness:** `bin/doctor` (or a pre-run check) should do a 1-token chat
  completion per model and flag template-render errors up front, so a broken
  model is caught before a full matrix run rather than looking like 3 tool
  failures.

## 5. google/gemma-4-26b-a4b-qat (15.64 GB)

Reasoning MoE (active ~4B). Template sanity-checked before the run.

| Tool | slugify /4 | debounce /4 | groupBy /3 | topwords /4 | **Total** | Notes |
|------|:---:|:---:|:---:|:---:|:---:|-------|
| caveman  | 4 | 4 | 3 | 4 | **15/15** | clean (66–277s) |
| codex    | 4 | 4 | 3 | 4 | **15/15** | clean (82–121s) |
| opencode | 4 | 4 | 3 | 4 | **15/15** | clean (124–144s) |
| aider    | 2 | 4 | 3 | 0 | **9/15**  | topwords **hung past 600s**; slugify 2/4 |

**Verdict:** excellent model — three tools at 15/15, fast for its size (MoE).
aider remains the lone underperformer, repeating its two signature failures.

**Suggestions to improve:**
- **aider** now shows a clear, reproducible pattern across models: (a) it gets
  **exactly 2/4 on slugify** every time (its edit-format consistently misses
  the collapse/trim cases), and (b) it **hangs past the timeout on one heavier
  case per slow model** (debounce @#3, topwords @#5). This points at aider's
  edit/reflection loop, not the models. Recommend testing aider with
  `--edit-format whole` and a hard per-call wall-clock cap.


## 6. qwen/qwen3-coder-30b (17.19 GB) — best for editing so far

| Tool | slugify /4 | debounce /4 | groupBy /3 | topwords /4 | **Total** | Notes |
|------|:---:|:---:|:---:|:---:|:---:|-------|
| aider    | 4 | 4 | 3 | 4 | **15/15** | **7–10s** — ~10× faster than the rest |
| caveman  | 4 | 4 | 3 | 4 | **15/15** | clean (43–150s) |
| codex    | 4 | 4 | 3 | 4 | **15/15** | correct; 1 lingering timeout + 1 post-edit error |
| opencode | 4 | 4 | 3 | 3 | **14/15** | missed one topwords edge (tie-break / n-limit) |

**Verdict:** the strongest model for these editing tasks. A purpose-built coding
model lifts every tool — and notably **fixes aider**: 15/15 and an order of
magnitude faster, because qwen3-coder emits aider's diff edit-format cleanly.
This confirms aider's earlier 9–13/15 scores were the *gemma* models failing to
produce its edit format, not an aider defect.

**Suggestions to improve:**
- **Pair aider with code-specialized models** (qwen3-coder class). It's the
  fastest tool by far when the model speaks its diff format; avoid it with
  general/instruct models that don't.
- **opencode**: the single topwords miss is worth a look — likely the
  alphabetical tie-break or the n-limit clamp. Minor.
