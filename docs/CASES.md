# Test cases & run procedure — full specification

This document specifies **every test case** precisely enough to **recreate its
code in another framework**, plus how a single test *run* is executed and scored.

- Overview & purpose: [../README.md](../README.md)
- Scoring (accuracy + speed): [SCORING.md](SCORING.md)
- Adding a new case: [ADDING-CASES.md](ADDING-CASES.md)
- Recorded results: [../BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md)

---

## How a test run works

For each `(tool, model, case)` triple, `bin/bench` does:

1. **Sandbox.** Copy `cases/<id>/workdir/` → `results/<ts>/sandbox/<tool>/<model>/<case>/`.
   This copy is the only thing the tool may edit.
2. **Drive the tool.** Feed `cases/<id>/task.md` to `adapters/<tool>.sh` on
   **stdin**, with `MODEL_ID=<model>` and the sandbox as cwd. The adapter runs
   the CLI **non-interactively** (LM Studio is the OpenAI-compatible backend).
   The tool edits files in place.
3. **Bound + time.** The run is killed after `--timeout` seconds (default 240;
   600 for slow models). Wall-clock is recorded as `seconds`; `status` is `ok`,
   `timeout`, or `error(<rc>)`.
4. **Grade.** Run `cases/<id>/check/run.sh` in the sandbox with `CASE_DIR`
   (the case source) and `REPO_ROOT` set. The grader copies any **pristine**
   test/lint files from `check/` over whatever is in the sandbox (so a tool
   can't game the score by editing the tests), runs them, and prints exactly:
   `RESULT pass=<n> total=<m>`.
5. **Record.** Append a row to `results/<ts>/results.csv`:
   `adapter,model,case,pass,total,score,seconds,status,trials` where
   `score = pass/total`. With `--trials N` the `score`/`seconds` are medians
   across the N trials — see [SCORING.md](SCORING.md).

Two metrics matter equally: **score** (correctness) and **seconds** (speed) —
see [SCORING.md](SCORING.md). `bin/report` aggregates both into leaderboards.

**Test runners are zero-install:** JS/TS use Node's built-in `node --test`
(`.ts` runs directly on Node 24 via type-stripping); Bash/lint cases use plain
shell assertions. No `npm install` is ever required.

### Case anatomy

```
cases/<id>/
  meta.json     # id, lang, title, points, category, difficulty, edit_files[, visible_tests]
  task.md       # the exact prompt handed to the tool (stdin)
  workdir/      # starter files copied into the sandbox (the editable code)
  check/
    run.sh      # grader: prints RESULT pass=N total=N (+ per-check CHECK lines)
    <pristine test/fixture/linter files>
```

### Categories

| category | meaning |
|----------|---------|
| `smoke` | connectivity only (not a quality score) |
| `bugfix` | fix a bug in existing code |
| `feature` | implement a stubbed function |
| `cli` | write/fix a shell script |
| `multi-file` | a change spanning ≥2 files |
| `self-verify` | test/lint suite ships in the workdir; the agent is told to **run it and iterate to green**. Grader re-runs pristine copies. |

### Difficulty (`difficulty`)

A declared tier used to **gate weaker/smaller models** to the work they can plausibly
do. Filter any run with `bin/bench --difficulty easy,medium` (also on `bin/stale`).

| tier | what it covers | small-model fit |
|------|----------------|-----------------|
| `easy` | smoke — one trivial edit to one file | any tool-calling model |
| `medium` | a real single-file task (bugfix / feature / cli) | the target band |
| `hard` | multi-file changes or self-verify (must run tools and iterate) | reserved for capable models |

The tiers reflect *what makes a case hard for a small model* — spanning files and
tool-iteration — not raw `points`.

### Per-check decomposition (grader contract)

Each grader is already broken into **atomic checks** (`RESULT pass=N total=N` means
N of M independent checks passed). Graders also emit one machine line per check:

```
CHECK <pass|fail> <id>
```

`bin/bench` records these to `results/<run>/checks.csv`
(`adapter,model,case,trial,status,check`), so you can see **which** sub-step a model
failed — e.g. a small model that nails the logic but fails the `lint` check, or only
the `punctuation run -> single hyphen` case. Write graders with the helpers in
[`lib/grader.sh`](../lib/grader.sh) (`check_pass` / `check_fail` / `check_eq` /
`tap_to_checks` / `emit_result`); the `RESULT` line stays authoritative for scoring.

---

## Cases

### smoke-00-hello — connectivity (category: smoke)
- **Runner:** shell. **Edit:** create `hello.txt`. **Max:** 2 (not counted in benchmark scoring).
- **Workdir:** empty (a `.gitkeep` placeholder).
- **Task:** create `hello.txt` whose entire contents are exactly `OK`.
- **Grader checks:** (1) `hello.txt` exists; (2) it contains `OK` (case-insensitive).
- **Recreate notes:** intentionally trivial — proves a tool can reach the model
  and write a file. Used by `bin/smoke`.

### js-01-slugify-bug — bugfix (category: bugfix)
- **Runner:** `node --test`. **Edit:** `src/slugify.js`. **Max:** 4.
- **Workdir:** `src/slugify.js` exports `slugify(input)` that only lowercases and
  replaces spaces (the bug).
- **Task:** make `slugify` (a) lowercase, (b) replace every run of
  non-alphanumeric chars with a single hyphen, (c) no leading/trailing hyphens.
- **Grader checks (4):**
  - `slugify('Hello World')` → `'hello-world'`
  - `slugify('  Foo  Bar!! ')` → `'foo-bar'`
  - `slugify('a@@@b')` → `'a-b'`
  - `slugify('Already-A-Slug')` → `'already-a-slug'`
- **Reference:** `input.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'')`.
- **Recreate notes:** the unedited buggy file passes 2/4 — a tool that doesn't
  actually edit scores 0.50, which distinguishes "no edit" from a real attempt.

### js-02-debounce-feature — feature (category: feature)
- **Runner:** `node --test`. **Edit:** `src/debounce.js`. **Max:** 4.
- **Workdir:** `src/debounce.js` exports a stub `debounce(fn, wait)` that throws.
- **Task:** implement `debounce(fn, wait)` returning a function that delays `fn`
  until `wait` ms after the last call; calls `fn` with the **latest** args and
  same `this`; exposes `.cancel()`.
- **Grader checks (4, timing-based with setTimeout):** invoked once after wait;
  uses latest args; `.cancel()` prevents invocation; preserves `this`.
- **Recreate notes:** tests `await sleep(ms)` around the `wait`; keep `wait`
  small (20–30 ms).

### ts-01-groupby — feature, TypeScript (category: feature)
- **Runner:** `node --test` on `.ts` (type-stripping). **Edit:** `src/groupBy.ts`. **Max:** 3.
- **Workdir:** stub `groupBy<T, K extends string|number>(items, keyOf): Record<K,T[]>`.
- **Task:** group items by `keyOf(item)`, preserving in-group input order; keep
  the exact generic signature and named export.
- **Grader checks (3):** parity grouping preserves order; group objects by a
  numeric key; empty input → `{}`.
- **Recreate notes:** signature must remain `Record<K, T[]>`; tests import from
  `./src/groupBy.ts`.

### bash-01-topwords — cli (category: cli)
- **Runner:** shell assertions over a fixture. **Edit:** `bin/topwords.sh`. **Max:** 4.
- **Workdir:** `bin/topwords.sh` stub that exits 1.
- **Task:** `topwords.sh <file> <n>` prints the `n` most frequent words as
  `<count> <word>`; words are lowercased, letters-only (split on non-letters);
  sort by descending count, ties broken alphabetically; print exactly `n` lines.
- **Fixture (`check/fixture.txt`):** `The cat, sat on the MAT.\nThe cat ran!\n`
  → counts: the=3, cat=2, mat/on/ran/sat=1.
- **Grader checks (4):** `n=3` → `3 the / 2 cat / 1 mat`; `n=2` → `3 the / 2 cat`;
  `n=9` prints 4–6 lines (no crash); top line is `3 the`.
- **Reference:** `tr A-Z a-z | grep -oE '[a-z]+' | sort | uniq -c | sort -k1,1nr -k2,2 | head -n N | awk '{print $1, $2}'`.

### js-03-multifile-cache — multi-file (category: multi-file)
- **Runner:** `node --test`. **Edit:** `src/store.js` **and** `src/cache.js`. **Max:** 5.
- **Workdir:**
  - `src/store.js`: `Store` class wrapping a `Map` with `set/get/has/size`;
    **missing** `delete(key)` and `keys()`.
  - `src/cache.js`: `Cache(capacity)` backed by a `Store`; `set` is a throwing stub.
- **Task:** add `Store.delete(key)→boolean` and `Store.keys()→[]` (insertion
  order); implement `Cache.set` as a capacity-bounded cache (evict the oldest
  key when full and the key is new; update-in-place otherwise; return `this`).
- **Grader checks (5):** store.delete removes + reports existence; store.keys
  insertion order; cache stores/reads; cache evicts oldest over capacity;
  updating an existing key does **not** evict.
- **Recreate notes:** genuinely needs both files; eviction uses
  `store.keys()[0]` + `store.delete(...)`.

### js-04-multifile-rename — multi-file (category: multi-file)
- **Runner:** `node --test`. **Edit:** `src/temperature.js` **and** `src/weather.js`. **Max:** 3.
- **Workdir:** `temperature.js` exports `toFahrenheit(c)`; `weather.js` imports it
  and uses it in `describe(c)` → `` `${c}°C is ${toFahrenheit(c)}°F` ``.
- **Task:** rename `toFahrenheit` → `celsiusToF` in **both** files (export +
  import + call sites); the old name must no longer be exported; keep `describe`
  output identical.
- **Grader checks (3):** `celsiusToF(0)=32`, `(100)=212`; `describe` output
  unchanged; `import * as temp; temp.toFahrenheit === undefined`.
- **Recreate notes:** all-or-nothing — an inconsistent rename makes the ESM
  named import fail to load, so the whole file fails (scores 0). A clean rename
  scores 3/3.

### js-05-multiselect-filter — self-verify (category: self-verify)
- **Runner:** `node --test`. **Edit:** `src/filter.js` (+ `index.html`). **Max:** 5.
- **Workdir (tests SHIP here):** `package.json` (`"test": "node --test"`),
  `src/filter.js` (single-select `filterByType`), `index.html` (radio controls),
  and **`filter.test.js`** (the agent can run `npm test`).
- **Task:** add `filterByTypes(items, types)` — return items whose `type` is in
  `types` (array or Set), original list order preserved; empty/null/undefined
  `types` → all items; pure (no mutation). Also convert `index.html` controls to
  multi-select checkboxes. **Run `npm test` and iterate until all pass.**
- **Grader checks (5, pristine `check/filter.test.js`):** empty/null → all;
  single type; multiple types in original order; no matches → `[]`; input not
  mutated.
- **Recreate notes:** the grader overwrites the shipped test with the pristine
  copy before scoring; the subtlety is that order follows the **list**, not the
  selection (`['B','A']` over `[A,B,C,A]` → apple, banana, avocado).

### js-06-lint-and-test — self-verify + lint (category: self-verify)
- **Runner:** `node --test` **plus** a zero-dep linter. **Edit:** `src/total.js`. **Max:** 4 (3 tests + 1 lint).
- **Workdir (tests + linter SHIP here):** `package.json`
  (`"test": "node --test"`, `"lint": "bash ./lint.sh"`), `.editorconfig`
  (`indent_style=space`, `trim_trailing_whitespace=true`,
  `insert_final_newline=true`), `src/total.js` (has a **bug** — accumulator
  starts at `1` — *and* style violations: a **tab** indent and **trailing
  whitespace**), `total.test.js`, and `lint.sh`.
- **Task:** make **both** `npm test` and `npm run lint` pass — fix the bug and
  clean the style. Iterate until both are green.
- **Grader checks:** 3 test assertions (`total([1,2,3])=6`, `total([])=0`,
  `total([-1,1,-2])=-2`) + **1 lint point** (passes only if `.editorconfig`
  rules hold: no tabs, no trailing whitespace, final newline). `total = tests+1`.
- **Linter (`lint.sh`):** zero-dependency, BSD-compatible; reads `.editorconfig`
  and checks `*.js` (excluding `*.test.js`) for trailing whitespace, tabs (when
  `indent_style=space`), and a final newline. Exits non-zero on any violation.
- **Recreate notes:** the lint point is **independent** of correctness, so a
  tool that fixes the logic but leaves trailing whitespace scores **3/4** — the
  realistic "agent left trailing whitespace" failure mode.

---

## What the case set is designed to expose

- **Did the tool actually edit?** (js-01's 2/4-when-unedited floor.)
- **Can the model drive the tool's edit format?** (codex/`apply_patch` needs a
  capable model; aider needs a model that speaks its diff format.)
- **Multi-file coordination.** (js-03, js-04.)
- **The verify-fix loop.** (js-05, js-06 — does the tool *run* the provided
  test/lint and iterate, or one-shot and stop?)
- **Style discipline under tooling.** (js-06's independent lint point.)
- **Speed at equal accuracy** — recorded for every run; see [SCORING.md](SCORING.md).
