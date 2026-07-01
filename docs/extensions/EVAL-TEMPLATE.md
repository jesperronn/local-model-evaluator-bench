# IDE plugin evaluation — template

Category: [IDE extensions / plugins](README.md) · Sibling spec: [../CARD-SPEC.md](../CARD-SPEC.md) (CLI tool/model cards)

> Two page types live in this directory:
> 1. **Per-plugin scorecard** (`<plugin>.md`) — one page per plugin, this
>    template. Criteria run **vertically** (one row each) because there are
>    11 of them — a wide plugin-× criteria matrix stopped being readable past
>    ~4 plugins and is retired.
> 2. **Per-IDE index** (`vscode.md`, `intellij.md`) — short ranking + links
>    into the scorecards above. No criteria table lives there anymore, just
>    the verdict and a one-line reason per plugin.

## Required sections (in order), per-plugin scorecard

| # | Section | Must answer |
|---|---------|-------------|
| 1 | **Quick verdict** | recommended-for / avoid, status, one-line why |
| 2 | **Metadata** | extension id, IDE(s), version, how it connects, last reviewed |
| 3 | **Criteria scorecard** | all 11 criteria, vertical, ✅/⚠️/❌ + evidence per row |
| 4 | **Pros** | bullet list |
| 5 | **Cons** | bullet list |
| 6 | **Runtime notes** | does it need both Ollama AND LM Studio to be usable, or does it excel on just one? (criterion 11 detail) |
| 7 | **Manual eval log** | dated entries: case run, pass/total, approval-prompt behavior observed |
| 8 | **Status** | verdict + date + what would change it |

## The criteria rubric (11 criteria, scored per plugin)

Score each ✅ (yes/strong) · ⚠️ (partial/caveat) · ❌ (no/blocker):

| # | Criterion | What it checks |
|---|-----------|-----------------|
| 1 | **No mandatory cloud login** | Works fully against a local endpoint; no forced account for the agentic path |
| 2 | **True agentic loop** | Multi-step plan → edit → execute → observe → iterate, not single-turn chat/autocomplete |
| 3 | **Tool-call reliability w/ local models** | Tolerates imperfect function-calling from local models (fallback formats) rather than silently breaking |
| 4 | **Approval memory** — hard gate | Persists "always allow" decisions per action/session/workspace. Re-prompting identically forever is disqualifying, full stop — see the rule below. |
| 5 | **Multi-file edits** | Native multi-file edit, not one-file-at-a-time |
| 6 | **Codebase awareness** | Repo indexing / autonomous file discovery |
| 7 | **Config transparency** | Plain-text/JSON config, no forced telemetry |
| 8 | **Active maintenance** | Not abandoned / not pivoted away from local-IDE use (cf. Roo Code archiving its VS Code extension, May 2026) |
| 9 | **IDE-native integration** | Inline diff view, per-hunk apply/reject, git awareness |
| 10 | **License/cost** | Open source or free tier sufficient for local-only workflow, no seat-gating of the local-model path |
| 11 | **Excels on at least one runtime** | Passes if the plugin works genuinely well against **either** Ollama **or** LM Studio alone — it does not need to support both well. A plugin that's flaky on LM Studio but rock-solid on Ollama (or vice versa) still passes; only fail this if it's shaky on **every** local runtime you can pair it with. |

> **Rule 1 (hard gate):** criterion 4 failing sends the plugin straight to
> "avoid" regardless of every other score — this mirrors CARD-SPEC's "speed
> must always be filled" principle: never let a good summary number hide the
> thing that makes daily use painful.
>
> **Rule 2 (runtime bar, not runtime breadth):** criterion 11 is intentionally
> low-bar. The goal is airgapped local use, not multi-runtime portability — a
> plugin that only works cleanly with LM Studio and never touches Ollama is
> still a full pass here. Only fail it if the plugin is unreliable on *every*
> runtime tried.

## Skeleton — per-plugin scorecard

```markdown
# <Plugin name>

Category: [IDE extensions / plugins](README.md) · Index: [vscode.md](vscode.md) / [intellij.md](intellij.md)

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | <e.g. primary agentic driver on VS Code + local Ollama> |
| **Status** | <recommended / runner-up / avoid / dropped> |
| **One-line why** | <the single sentence that would change someone's mind> |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | <e.g. saoudrizwan.claude-dev> |
| **IDE(s)** | <VS Code / IntelliJ / both> |
| **Version** | <version tested, or "not yet installed"> |
| **How it connects** | <provider settings, base URL, auth> |
| **Last reviewed** | <YYYY-MM-DD> |

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | | |
| 2 | True agentic loop | | |
| 3 | Tool-call reliability w/ local models | | |
| 4 | Approval memory (hard gate) | | |
| 5 | Multi-file edits | | |
| 6 | Codebase awareness | | |
| 7 | Config transparency | | |
| 8 | Active maintenance | | |
| 9 | IDE-native integration | | |
| 10 | License/cost | | |
| 11 | Excels on at least one runtime | | |

## Pros
-

## Cons
-

## Runtime notes
<Ollama-only, LM Studio-only, both, or neither — and what "excels" looked like>

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|

## Status
**<date>** — <verdict + what would trigger a re-rank>
```
