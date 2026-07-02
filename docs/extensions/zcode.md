# ZCode (Z.ai standalone desktop app)

Category: [IDE extensions / plugins](README.md) · Not a VS Code/JetBrains plugin — evaluated here because it's the same "GUI agent, manually driven" shape as the rest of this category.

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | nothing yet in this repo — no headless mode, so it can't join the automated matrix, and airgapped/telemetry behavior for the local-provider path is unconfirmed |
| **Status** | not automatable — web-researched only, 2026-07-02 |
| **One-line why** | Unlike Kilo Code's cloud-locked CLI, ZCode's custom-provider settings genuinely accept an OpenAI/Anthropic-compatible endpoint (including self-hosted), but it ships as a login-gated standalone desktop app with no CLI/headless twin — so it fails the automation bar outright and the "does it phone home even on the local path" question is still open. |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | N/A — standalone desktop app, not an IDE extension |
| **IDE(s)** | none; native app for macOS, Windows, Linux (beta) |
| **Version** | not installed in this repo |
| **How it connects** | First-party: signs in with a Z.ai account and uses the GLM Coding Plan entitlement (GLM-5.2), no manual endpoint config. Custom provider: Model Settings → Add Provider → Anthropic- or OpenAI-compatible endpoint + API key; docs explicitly mention "self-hosted services on a private network" as a supported case. |
| **Last reviewed** | 2026-07-02 (web research only — released today, not yet installed) |

> Released 2026-07-02. Positioned by Z.ai as "the official harness for GLM-5.2," competing with Cursor, Claude Code, GitHub Copilot, and Antigravity. Pricing: GLM Coding Plan Lite $16.20/mo, Pro $64.80/mo, Max $144/mo — no free tier found.

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ❌ | App requires signing in with a Z.ai account to launch at all, even before touching model settings — a custom local provider does not remove the login gate. |
| 2 | True agentic loop | ⚠️ **unverified** | Marketed as an "Agentic Development Environment" with 20+ built-in coding tools; no hands-on confirmation of plan→edit→execute→observe behavior. |
| 3 | Tool-call reliability w/ local models | ⚠️ **unverified** | Custom-provider path exists, but no report yet of running it against a local GLM-5.2 (or other) weight served via Ollama/vLLM. |
| 4 | Approval memory (hard gate) | ⚠️ **unverified** | Not tested. Given the hard-gate rule, this alone blocks any "recommended" verdict until checked. |
| 5 | Multi-file edits | ⚠️ **unverified** | Not tested. |
| 6 | Codebase awareness | ⚠️ **unverified** | Not tested. |
| 7 | Config transparency | ⚠️ | Requires account login and a paid plan for the first-party GLM-5.2 path; unclear whether the app phones home for telemetry/license checks even when a custom local provider is selected. |
| 8 | Active maintenance | ✅ | Brand new (released today), first-party from Z.ai, actively promoted — no abandonment risk in the near term, but also no track record. |
| 9 | IDE-native integration | N/A | Standalone app, not embedded in an existing IDE — has its own editor/diff UI instead of augmenting VS Code/JetBrains. |
| 10 | License/cost | ❌ | Closed-source desktop app; the first-party model path is subscription-gated ($16.20–$144/mo) with no stated free tier. The custom-provider path itself may be free to configure, but the app's login gate still applies. |
| 11 | Excels on at least one runtime | ⚠️ **unverified** | Docs say custom providers "automatically fetch and load the available model list" from an OpenAI/Anthropic-compatible endpoint, which should work against LM Studio or an Ollama OpenAI-compat shim in principle — not yet tried against either. |

## Pros
- Genuine custom-provider support for OpenAI/Anthropic-compatible endpoints, explicitly including self-hosted services on a private network — a real step up from Kilo Code's CLI, which rejects any model not registered with kilo.ai's cloud backend.
- First-party GLM-5.2 integration is presumably well-tuned for that model specifically, if the subscription path is used.
- Actively shipped and promoted on day one; unlikely to be abandoned in the short term.

## Cons
- Mandatory account login to launch the app at all, regardless of which model provider is configured — fails criterion 1 outright, unlike this repo's local-first tools.
- No CLI or headless mode found — cannot be wired into `adapters/<name>.sh` or run through `bin/nightly`/`bin/smoke`, so it never enters the automated matrix; any future verdict here stays a manual GUI eval only.
- Whether the local/self-hosted custom-provider path is genuinely airgapped (no phone-home for auth/telemetry/license checks) is undocumented — this is the single fact that would decide whether it's worth a manual eval slot at all.
- Everything on this page is from vendor docs and day-one press coverage; zero hands-on verification.

## Runtime notes
Not tried against Ollama or LM Studio. In principle the "Anthropic/OpenAI-compatible custom provider" setting should point at either, since ZCode auto-detects the model list from the endpoint — but this needs a hands-on check, and the account-login requirement means it can't be made to run fully offline even if the endpoint itself is local.

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|
| — | not yet run | — | — | — |

## Status
**2026-07-02** — not automatable (no headless CLI found) and not recommended pending verification of the login/telemetry requirement on the custom-provider path. Re-rank triggers: (a) confirmation of whether the app can run fully offline/airgapped once a local custom provider is configured, (b) discovery of a headless/CLI mode that would let it join the automated `adapters/` matrix, (c) a hands-on manual run confirming or denying approval-memory (criterion 4, hard gate).
