# Junie (JetBrains agent)

Category: [IDE extensions / plugins](README.md) · Index: [intellij.md](intellij.md)

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | primary agentic driver on IntelliJ + local Ollama/LM Studio, pending hands-on verification |
| **Status** | top pick — web-researched, not yet hand-verified in this repo |
| **One-line why** | JetBrains' own native agent, GA since June 2026, with documented direct support for Ollama/LM Studio/LiteLLM as custom LLM backends and no cloud requirement for that path. |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | bundled with / installable into JetBrains IDEs (jetbrains.junie) |
| **IDE(s)** | IntelliJ IDEA (and other JetBrains IDEs) |
| **Version** | GA as of June 2026 ("out of beta"); exact version not yet installed/recorded here |
| **How it connects** | Custom LLM backend setting → Ollama (default `http://localhost:11434`), LM Studio, or LiteLLM; JetBrains states prompts/code stay local when configured this way |
| **Last reviewed** | 2026-07-01 (web research only) |

## Automation feasibility

**Possible, but one unknown blocks it.** Junie ships a CLI (EAP as of 2026) with a documented headless mode for CI: `junie --auth="$JUNIE_API_KEY" "<prompt>"`. It separately supports custom local-model profiles (JSON, pointing at Ollama's `http://localhost:11434` or LM Studio). **Open question:** does `--auth` require a JetBrains-account credential even when the model itself is routed to a local endpoint, or is it purely a local API-key/profile selector? If the former, this fails criterion 1 (no mandatory cloud login) for the *automatable* path specifically, even though the interactive IDE path claims to be local-only. **Next step before writing an adapter:** run `junie --auth=... "prompt"` against a local-only profile with network access blocked and confirm it still works — that single test resolves both the automation-feasibility and airgap questions at once. Also note: EAP status means the CLI's flags/behavior may still change.

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ✅ | Documented custom-LLM path bypasses JetBrains AI cloud entirely when pointed at Ollama/LM Studio/LiteLLM. |
| 2 | True agentic loop | ✅ | Positioned as JetBrains' full coding agent, not a chat/completion assistant. |
| 3 | Tool-call reliability w/ local models | ⚠️ **unverified** | No local (non-frontier) model reliability data found yet — untested against weaker function-calling models. |
| 4 | Approval memory (hard gate) | ⚠️ **unverified** | Not yet tested — this is the single most important thing to confirm before trusting the "top pick" ranking. |
| 5 | Multi-file edits | ⚠️ **unverified** | Not documented in the sources reviewed; assume capable given "full coding agent" positioning, but confirm. |
| 6 | Codebase awareness | ✅ | Inherits IntelliJ's native project indexing — expected to be strong by construction. |
| 7 | Config transparency | ⚠️ | Custom-LLM config exists in docs but hasn't been inspected directly in this repo; verify no hidden telemetry/update calls. |
| 8 | Active maintenance | ✅ | JetBrains-backed, just left beta — strong maintenance signal. |
| 9 | IDE-native integration | ✅ (expected) | Being JetBrains' own product, native integration quality should be best-in-class for IntelliJ — verify once installed. |
| 10 | License/cost | ⚠️ **verify** | Unclear whether the local-LLM agentic path requires a paid JetBrains AI/Junie subscription even though inference itself runs locally — check before assuming free local use. |
| 11 | Excels on at least one runtime | ⚠️ **unverified** | Ollama and LM Studio both documented as backends; neither confirmed hands-on. |

## Pros
- Purpose-built by JetBrains for JetBrains IDEs — tightest expected integration with project model, run configs, and indices.
- Explicit, documented local backend support (Ollama default URL, LM Studio, LiteLLM) rather than a bolted-on OpenAI-compatible option.
- Recently GA (June 2026) — active platform investment, not a side experiment.

## Cons
- Zero hands-on verification yet in this repo: approval memory, tool-call reliability, and multi-file behavior with local models are all open questions.
- Licensing for the local-LLM path is unclear — must confirm it doesn't require a paid subscription tier before recommending it as the free/airgapped-friendly default.
- As JetBrains-first software, worth explicitly checking for telemetry/update network calls even when the model backend is local, given the airgap requirement.

## Runtime notes
Documents both Ollama and LM Studio; neither has been hands-on verified. Do not claim a specific "excels on X" until a manual run exists.

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|
| — | not yet run | — | — | — |

## Status
**2026-07-01** — web-researched top pick, contingent entirely on a hands-on run. Re-rank triggers: (a) approval-memory confirmed working or failing, (b) licensing clarified for the local-LLM path, (c) a direct case run producing a pass/total.
