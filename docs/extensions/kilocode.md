# Kilo Code (VS Code extension)

Category: [IDE extensions / plugins](README.md) · Index: [vscode.md](vscode.md) · See also: [tools/kilocode.md](../tools/kilocode.md) (standalone CLI — a **different product**, cloud-only)

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | runner-up agentic driver on VS Code, especially if migrating existing `.roomodes`/`.roo/rules/` config from Roo Code |
| **Status** | runner-up — web-researched, not yet hand-verified in this repo |
| **One-line why** | Active Cline/Roo fork with documented local Ollama + LM Studio support and an Orchestrator mode, but newer and VC-funded — watch for a cloud pivot like Roo Code's. |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | kilocode.kilo-code (VS Code Marketplace) |
| **IDE(s)** | VS Code |
| **Version** | not yet installed in this repo |
| **How it connects** | Configure a local endpoint (Ollama or LM Studio) directly in extension settings; no login required for the local-model path |
| **Last reviewed** | 2026-07-01 (web research only) |

> **Do not confuse with the standalone `kilo` CLI** (`@kilocode/cli`, [tools/kilocode.md](../tools/kilocode.md)) — that product validates all models against kilo.ai's cloud backend and has no working local/offline path as of the 2026-06-18 investigation. This page is about the **VS Code extension**, which is a separate codebase/product with documented local-model support.

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ✅ | Local endpoint configurable directly; no account needed for that path. |
| 2 | True agentic loop | ✅ | Forked from Cline/Roo — same tool-call-driven multi-step loop, plus Orchestrator mode for subtask routing. |
| 3 | Tool-call reliability w/ local models | ⚠️ **unverified** | Inherits Cline's tool-call format; no independent local-model reliability data yet. |
| 4 | Approval memory (hard gate) | ⚠️ **unverified** | Not yet tested — must confirm before trusting for daily use, given how disqualifying a failure here is. |
| 5 | Multi-file edits | ✅ (inherited) | Same tool-call architecture as Cline, which supports it natively. |
| 6 | Codebase awareness | ✅ (inherited) | Same autonomous file-discovery lineage as Cline. |
| 7 | Config transparency | ⚠️ | VC-funded ($8M seed) — worth checking settings/telemetry defaults directly rather than assuming parity with Cline. |
| 8 | Active maintenance | ✅ | Actively developed, claims 1.5M+ users; but flag the funding as a future-pivot risk (cf. Roo Code). |
| 9 | IDE-native integration | ✅ | Adds inline autocomplete on top of Cline/Roo's diff-view agent UI — potentially better integrated than either parent. |
| 10 | License/cost | ✅ | Open source; local-model path not seat-gated as of current docs. |
| 11 | Excels on at least one runtime | ⚠️ **unverified** | Documents both Ollama and LM Studio; neither confirmed hands-on in this repo yet. |

## Pros
- Ingests existing `.roomodes` / `.roo/rules/` config — low-friction migration path from Roo Code.
- Orchestrator mode gives structured subtask routing (architect → coder → debugger) that neither Cline nor plain Continue offer.
- Documents both Ollama and LM Studio explicitly as local backends.
- Inline autocomplete bundled with the agent — one extension instead of two.

## Cons
- VC-funded with a large seed round — the exact pattern that preceded Roo Code's cloud pivot; no guarantee the local-model path stays first-class.
- Smaller independent track record than Cline; most claims here are from the vendor's own docs/marketing, not third-party local-model reports.
- Approval-memory and tool-call reliability with local (non-frontier) models are both unverified — do not treat this page's ranking as confirmed until the manual eval log below has entries.

## Runtime notes
Documented for both Ollama and LM Studio; neither has been hands-on verified in this repo. Needs a manual run before claiming which runtime it "excels" on.

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|
| — | not yet run | — | — | — |

## Status
**2026-07-01** — web-researched only, runner-up pending hands-on verification. Re-rank triggers: (a) a manual run confirming/denying approval memory, (b) any sign of a cloud-only pivot following the funding round, (c) direct comparison against Cline on the same case set.
