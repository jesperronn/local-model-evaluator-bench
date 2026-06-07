# Adding a test case

Related: [README](../README.md) · [CASES.md](CASES.md) (spec of existing cases) · [SCORING.md](SCORING.md)


A case is a folder under `cases/`. Copy an existing one and adapt it.

```
cases/<id>/
  meta.json          # id, lang, title, points, category, edit_files
  task.md            # the exact prompt the model is given (stdin to the adapter)
  workdir/           # starter files copied into the sandbox (the code to edit)
  check/
    run.sh           # grader — runs in the sandbox, prints: RESULT pass=N total=N
    <tests/fixtures> # hidden; copied into the sandbox only at grading time
```

## Conventions

- **id / folder name**: `<lang>-<nn>-<slug>`, e.g. `js-03-merge-intervals`.
- **task.md**: state the goal, the required exported name / file path, the
  rules, and a couple of examples. Tell the model *not* to rename things the
  tests import.
- **workdir/**: a compiling-but-incomplete or buggy starting point. Never put
  the answer or the tests here.
- **check/run.sh**: receives `$CASE_DIR` (this case's source dir) and
  `$REPO_ROOT`; CWD is the populated sandbox. It must end by printing
  `RESULT pass=<n> total=<m>`.

## JS / TS cases (zero install)

Use Node's built-in runner via the shared scorer. `check/run.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
cp "$CASE_DIR/check/foo.test.js" ./foo.test.js     # or .test.ts
exec bash "$REPO_ROOT/lib/node-test-score.sh" ./foo.test.js
```

Tests import the model-edited source by its path, e.g.
`import { foo } from './src/foo.js'` (`.ts` works directly on Node 24+).

## Bash / CLI cases

Grade by running the produced script and asserting output. Keep your own
`pass`/`total` counters and print the `RESULT` line at the end — see
`cases/bash-01-topwords/check/run.sh` for the pattern.

## Verify your grader before committing

Drop a correct reference solution into a throwaway sandbox and confirm full
marks, and a wrong one to confirm it doesn't:

```bash
sb=$(mktemp -d); cp -R cases/<id>/workdir/. "$sb/"
# ...write a correct solution into $sb...
( cd "$sb" && CASE_DIR="$PWD/cases/<id>" REPO_ROOT="$PWD" bash cases/<id>/check/run.sh )
```

A case isn't done until a correct solution scores `pass==total` and an
obviously-wrong one scores `0`.
