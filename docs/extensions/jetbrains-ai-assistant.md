# JetBrains AI Assistant (non-Junie)

Category: [IDE extensions / plugins](README.md) · Index: [intellij.md](intellij.md) · See also: [junie.md](junie.md)

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | undetermined — needs a scoping pass against Junie before this page is trustworthy |
| **Status** | watch — likely redundant with or superseded by Junie |
| **One-line why** | Historically chat/completion-first; documents local model support too, but it's unclear whether it has a genuine agentic loop distinct from Junie now that Junie is GA. |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | JetBrains AI Assistant plugin (marketplace id 22282) |
| **IDE(s)** | IntelliJ IDEA and other JetBrains IDEs |
| **Version** | not yet installed/recorded |
| **How it connects** | Third-party/local model settings documented (Ollama, LM Studio) per JetBrains AI Assistant docs |
| **Last reviewed** | 2026-07-01 (web research only) |

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ✅ (for local model config) | Local model settings documented directly. |
| 2 | True agentic loop | ⚠️ **unverified — likely the deciding question** | Historically positioned around chat and inline completion; unclear if a genuine plan→edit→execute→iterate loop exists separate from Junie. This is the single fact that determines whether this page is worth keeping. |
| 3 | Tool-call reliability w/ local models | — unverified | Blocked on answering criterion 2 first. |
| 4 | Approval memory (hard gate) | — unverified | Blocked on answering criterion 2 first. |
| 5 | Multi-file edits | — unverified | — |
| 6 | Codebase awareness | ✅ (expected) | Native IntelliJ indexing, same as any JetBrains-integrated tool. |
| 7 | Config transparency | ⚠️ | Not yet inspected directly. |
| 8 | Active maintenance | ✅ | JetBrains-backed. |
| 9 | IDE-native integration | ✅ (expected) | Native plugin. |
| 10 | License/cost | ⚠️ **verify** | Check whether local-model use requires a paid tier. |
| 11 | Excels on at least one runtime | — unverified | — |

## Pros
- Documents local model wiring (Ollama, LM Studio) similar to Junie.
- Likely lowest-friction install since it's a long-standing, bundled-adjacent JetBrains plugin.

## Cons
- Primary open question — whether it offers agentic capability at all distinct from Junie — is unanswered; most rows above are blocked on that.
- Risk of this page being redundant: if it turns out to be chat/completion-only, it should be dropped from the agentic-tools comparison entirely and left out of [intellij.md](intellij.md)'s ranking.

## Runtime notes
Not evaluated — contingent on resolving whether this product has an agentic loop worth comparing against Junie at all.

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|
| — | not yet run | — | — | — |

## Status
**2026-07-01** — watch, pending a scoping pass. Next action: determine via JetBrains docs or a quick hands-on check whether this product has an agentic (multi-step tool-calling) mode distinct from Junie. If not, drop this page and remove it from [intellij.md](intellij.md)'s ranking; if yes, fill in the scorecard properly.
