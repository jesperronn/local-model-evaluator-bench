# IDE extensions / plugins

Related: [../tools/](../tools/) (CLI adapters) · [../models/](../models/) · [../SETUP.md](../SETUP.md#4-editor-extensions-same-lm-studio-server)

This is a **separate evaluation category** from the CLI adapters in
[`docs/tools/`](../tools/). Those are driven non-interactively by the harness
(`adapters/<name>.sh`) and scored automatically. IDE extensions are GUI clients
(VS Code / JetBrains) that you drive **by hand** against the same LM Studio
endpoint, then grade with each case's own grader (see the manual procedure in
[SETUP.md §4](../SETUP.md#4-editor-extensions-same-lm-studio-server)).

Because they're not in the automated matrix, their model recommendations are
**heuristic** — transferred from how each model behaves on the CLI adapters
that work most like the extension (structured tool-calling + multi-turn agentic
loops), not from direct measurement. Each page says so explicitly and flags
which numbers are measured vs inferred.

## Pages

| Extension | IDE | Page | Status |
|-----------|-----|------|--------|
| Cline | VS Code | [cline.md](cline.md) | heuristic — no direct Cline runs yet |
| Continue | VS Code / JetBrains | _planned_ | — |
| Roo Code | VS Code | _planned_ | — |
| ProxyAI (CodeGPT) | JetBrains | _planned_ | — |

> **Long-term:** each extension gets its own page in this directory, following
> the same structure as `cline.md`. Add a row above when you start one.

## What a page should cover

1. **Connection settings** — exact provider/Base URL/model-id fields, with the
   recommended values for a local LM Studio setup.
2. **Why the extension is different** — its prompt size, edit format, and
   tool-calling style, since those decide which models cope with it.
3. **Heuristic model evaluation** — best → worst, with the reasoning and the
   CLI adapter each judgement is transferred from. Placeholders where the
   underlying model data is thin.
4. **Manual eval procedure** — how to run a `cases/<id>/` task by hand and grade
   it, so heuristics can eventually be replaced with measured results.
