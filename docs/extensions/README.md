# IDE extensions / plugins

Related: [../tools/](../tools/) (CLI adapters) · [../models/](../models/) · [../SETUP.md](../SETUP.md#4-editor-extensions-same-lm-studio-server)

This is a **separate evaluation category** from the CLI adapters in
[`docs/tools/`](../tools/). IDE extensions are GUI clients (VS Code /
JetBrains) that you drive **by hand** against the same LM Studio endpoint,
then grade with each case's own grader (see the manual procedure in
[SETUP.md §4](../SETUP.md#4-editor-extensions-same-lm-studio-server)) —
**except** where the same agent ships a separate headless CLI, in which case
it *can* join the automated matrix. See **Automation feasibility** below.

Because they're not in the automated matrix, their model recommendations are
**heuristic** — transferred from how each model behaves on the CLI adapters
that work most like the extension (structured tool-calling + multi-turn agentic
loops), not from direct measurement. Each page says so explicitly and flags
which numbers are measured vs inferred.

## Index pages (ranking, per IDE)

| Page | Scope |
|------|-------|
| [vscode.md](vscode.md) | Ranking + links: Cline / Kilo Code / Continue.dev / Roo Code (dropped) |
| [intellij.md](intellij.md) | Ranking + links: Junie / Continue.dev / JetBrains AI Assistant |

> **Approval-memory is a hard gate** on both index pages: a plugin that can't
> persist "always allow" decisions and re-prompts for every identical action
> is ranked "avoid" regardless of other scores. This was added after direct
> experience with Continue.dev's Agent mode being unworkable on that basis.

## Per-plugin scorecards

One page per plugin, each scored against the same **11-criteria vertical
rubric** in [EVAL-TEMPLATE.md](EVAL-TEMPLATE.md) — vertical because a
plugin-× criteria matrix stopped being readable past ~4 plugins.

| Plugin | IDE(s) | Page | Status |
|--------|--------|------|--------|
| Cline | VS Code | [cline.md](cline.md) | top pick — scorecard added, mostly heuristic |
| Kilo Code | VS Code | [kilocode.md](kilocode.md) | runner-up — web-researched only |
| Continue.dev (Agent mode) | VS Code / IntelliJ | [continue.md](continue.md) | **avoid — disqualified on approval memory** |
| Junie | IntelliJ | [junie.md](junie.md) | top pick — web-researched only |
| JetBrains AI Assistant | IntelliJ | [jetbrains-ai-assistant.md](jetbrains-ai-assistant.md) | watch — may be redundant with Junie |
| Roo Code | VS Code | [roocode.md](roocode.md) | dropped — archived May 2026, pivoted to cloud-only |

> **Long-term:** each scorecard's manual-eval log starts empty; fill it in via
> the procedure on [vscode.md](vscode.md)/[intellij.md](intellij.md) as real
> runs happen, and flip unverified (⚠️) rows to measured ✅/❌.

## Automation feasibility

Each agent may have a **headless CLI twin** of its GUI extension — same
agent core, no interactive UI — which can be wired into `adapters/<name>.sh`
and run through `bin/nightly`/`bin/smoke` like any CLI tool.

| Agent | Headless CLI exists? | Status |
|-------|----------------------|--------|
| Cline | ✅ `cline` binary | **Already automated** — [`adapters/cline-lms.sh`](../../adapters/cline-lms.sh) (+ mlx/ollama variants), in `bin/nightly`/`bin/smoke` today. See [cline.md](cline.md#automation-feasibility). |
| Continue.dev | ✅ `cn` (`@continuedev/cli`) | **Feasible, not built** — headless via `cn -p`, same local-model config as the extension. See [continue.md](continue.md#automation-feasibility). |
| Junie | ✅ `junie` CLI (EAP) | **Feasible, one unknown** — headless via `junie --auth=...`; unclear if `--auth` requires a JetBrains-account credential even for local-model routing. Resolve before adapting. See [junie.md](junie.md#automation-feasibility). |
| Kilo Code | ⚠️ `@kilocode/cli` exists but is a **different, cloud-only product** | Not automatable for local use — see [tools/kilocode.md](../tools/kilocode.md). |
| JetBrains AI Assistant, Roo Code | ❌ none found | Manual-only (Roo Code is archived anyway). |

**Critical limitation of all headless automation:** these CLIs auto-execute
tool calls with no approval prompt, so an automated pass/total score
measures the agent loop's accuracy/speed — it says nothing about the
criterion-4 approval-memory behavior, which only exists in the GUI. The two
checks (automated benchmark vs. manual approval-UX audit) stay separate and
both are needed before fully trusting a "recommended" verdict.

## Other extensions (not yet scorecarded)

| Extension | IDE | Status |
|-----------|-----|--------|
| Cursor | VS Code fork | _planned_ — GUI-only, no headless mode; explore manual eval procedure |
| ProxyAI (CodeGPT) | JetBrains | _planned_ |

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
