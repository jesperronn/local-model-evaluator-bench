# Recommended agentic plugins — IntelliJ IDEA

Category: [IDE extensions / plugins](README.md) · Rubric: [EVAL-TEMPLATE.md](EVAL-TEMPLATE.md) · See also: [vscode.md](vscode.md)

> Full 11-criteria scorecards live on each plugin's own page (linked below) —
> vertical layout, matching the VS Code index. This page is just the ranking.

## Quick verdict

| Rank | Plugin | Status | Scorecard |
|------|--------|--------|-----------|
| 1 (top pick, provisional) | Junie | JetBrains' native agent, GA June 2026, documents Ollama/LM Studio/LiteLLM support. **Confirmed 2026-07-01: its CLI twin hard-requires a JetBrains cloud auth token even for local-only inference** — automation/CLI path is disqualified. The IDE-embedded agent itself is still untested and may or may not share that gate; treat this rank as provisional until it's hands-on verified. | [junie.md](junie.md) |
| 2 (runner-up, provisional) | Continue.dev (Agent mode) | Same core as VS Code build — carries the **same approval-memory disqualifier** for the GUI extension until re-tested specifically on IntelliJ's plugin sandbox. Its headless `cn` CLI, by contrast, is confirmed working (8/8 on the full case set) — see [continue.md](continue.md). | [continue.md](continue.md) |
| watch | JetBrains AI Assistant | Unclear if it has an agentic loop distinct from Junie; needs a scoping pass before it belongs in this ranking at all. | [jetbrains-ai-assistant.md](jetbrains-ai-assistant.md) |

> As of 2026-07-01. Approval-memory (criterion 4) is a hard gate — see
> [EVAL-TEMPLATE.md](EVAL-TEMPLATE.md#the-criteria-rubric-11-criteria-scored-per-plugin).
> The IDE-embedded plugins themselves remain hand-unverified; only the
> **CLI twins** (`cn` for Continue, `junie` for Junie) have been hands-on
> tested in this repo so far, with opposite outcomes.

## Status
**2026-07-01** — Junie's CLI automation path is confirmed blocked on cloud auth; Continue's CLI automation path is confirmed working. Neither IDE-embedded GUI plugin has been hands-on tested yet — that remains the next step for both before either "top pick" or "avoid" can be trusted for the actual daily-driver experience. Re-rank triggers: (a) a hands-on IDE-plugin run for Junie, (b) an IntelliJ-specific Continue.dev approval-memory re-test, (c) clarity on JetBrains AI Assistant vs. Junie overlap.
