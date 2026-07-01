# Junie (JetBrains agent)

Category: [IDE extensions / plugins](README.md) · Index: [intellij.md](intellij.md)

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | possibly the IDE-embedded agent on IntelliJ + local Ollama/LM Studio — still unverified hands-on; **not** recommended for automated/headless use |
| **Status** | top pick for the IDE-embedded path (unverified), but its CLI twin is confirmed blocked on a cloud-auth requirement |
| **One-line why** | JetBrains' own native agent, GA since June 2026, documents local Ollama/LM Studio/LiteLLM backends — but hands-on testing of the CLI (2026-07-01) found it refuses to run without a JetBrains-issued auth token even when every model call is routed to a local endpoint. The IDE-embedded agent itself is still untested and may behave differently. |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | bundled with / installable into JetBrains IDEs (jetbrains.junie) |
| **IDE(s)** | IntelliJ IDEA (and other JetBrains IDEs) |
| **Version** | GA as of June 2026 ("out of beta"); exact version not yet installed/recorded here |
| **How it connects** | Custom LLM backend setting → Ollama (default `http://localhost:11434`), LM Studio, or LiteLLM; JetBrains states prompts/code stay local when configured this way |
| **Last reviewed** | 2026-07-01 (web research only) |

## Automation feasibility

**Resolved 2026-07-01 — blocked.** Installed Junie CLI 2144.7 (`curl -fsSL https://junie.jetbrains.com/install.sh | bash`) and tested the local-only path directly:

```
junie --litellm-url http://localhost:1234/v1 --litellm-api-key lm-studio \
  --skip-update-check --output-format text --project <dir> "<prompt>"
```

Result: **`Cannot find authorization. Please authenticate before running Junie.`** — even with a LiteLLM URL pointed at LM Studio and a local API key set, Junie CLI still demands `--auth`/`JUNIE_API_KEY`, a token generated via a signup flow at junie.jetbrains.com/cli. There is no flag combination that skips this, regardless of where inference actually happens.

**This fails criterion 1 (no mandatory cloud login) for the automatable path specifically** — the interactive IDE-embedded agent may still be locally-routable as documented, but the CLI twin that would let this join the automated benchmark matrix requires a JetBrains-issued credential. Not pursuing an `adapters/junie-lms.sh` unless that changes (e.g. a future EAP build adds an auth-free local mode) or you're willing to create a JetBrains account solely to mint a CLI token.

**Note:** the `-t`/`1` test-runner noise seen on first invocation (before hitting the auth wall) came from Junie CLI's own arg parser misinterpreting flags — unrelated to the auth finding, just an EAP rough edge.

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ⚠️ **split verdict** | IDE-embedded agent: documented custom-LLM path claims to bypass JetBrains AI cloud when pointed at Ollama/LM Studio/LiteLLM (not yet hands-on confirmed). **CLI twin: confirmed to require a JetBrains-issued `--auth` token even with `--litellm-url` set to a local endpoint** — see [Automation feasibility](#automation-feasibility). Score the CLI path ❌ specifically. |
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
- Purpose-built by JetBrains for JetBrains IDEs — tightest expected integration with project model, run configs, and indices (still unverified hands-on).
- Explicit, documented local backend support (Ollama default URL, LM Studio, LiteLLM) rather than a bolted-on OpenAI-compatible option — for the IDE-embedded agent specifically; the CLI does not honor this without cloud auth (see Cons).
- Recently GA (June 2026) — active platform investment, not a side experiment.

## Cons
- **Confirmed (2026-07-01): the CLI cannot run in a local-only/airgapped mode.** Even with `--litellm-url` pointed at LM Studio, it hard-fails with "Cannot find authorization. Please authenticate before running Junie." unless given a JetBrains-issued `--auth`/`JUNIE_API_KEY` token from a signup flow. This rules it out for this repo's automated benchmark harness.
- Whether the **IDE-embedded** agent (as opposed to the CLI) can actually run auth-free against a local model is still unverified — the documented custom-LLM settings may or may not bypass the same gate. Do not assume the IDE path is clean just because the CLI path failed, or vice versa; test separately.
- Approval memory, tool-call reliability, and multi-file behavior with local models remain untested for the IDE-embedded path.
- Licensing for the local-LLM path is unclear — must confirm it doesn't require a paid subscription tier before recommending it as the free/airgapped-friendly default.
- As JetBrains-first software, worth explicitly checking for telemetry/update network calls even when the model backend is local, given the airgap requirement.
- Minor EAP rough edge: the CLI's arg parser emitted spurious "Test file not found" noise for `-t`/numeric-looking tokens before the auth check even ran — cosmetic, but a sign the CLI is still early.

## Runtime notes
Documents both Ollama and LM Studio for the IDE-embedded agent; neither confirmed hands-on. The CLI twin cannot reach either runtime in practice because it hard-stops at the auth check before any model call is made — so no runtime-quality signal exists yet for the CLI at all, independent of Ollama vs. LM Studio.

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|
| 2026-07-01 | CLI local-only smoke attempt (`junie --litellm-url http://localhost:1234/v1 --litellm-api-key lm-studio ... "Fix the bug in greet.js"`) | **blocked, 0/1** | n/a — never reached the agent loop | Hard-failed at auth check: `Cannot find authorization. Please authenticate before running Junie.` No local-only flag combination bypasses this. Confirms the CLI requires a JetBrains-issued token regardless of where inference is routed. |
| — | IDE-embedded agent, any case | not yet run | — | Still open — the IDE path may or may not share the CLI's auth requirement. Requires installing the Junie IDE plugin and testing by hand per the [manual eval procedure](intellij.md#manual-eval-procedure). |

## Status
**2026-07-01** — split status. **CLI path: confirmed not usable** for local/airgapped or automated use — hard cloud-auth requirement, no adapter written (see [Automation feasibility](#automation-feasibility)). **IDE-embedded path: still unverified**, remains a plausible top pick on paper but needs the same hands-on test the CLI just failed before trusting it. Re-rank triggers: (a) a hands-on IDE-plugin run confirming or denying local-only operation, (b) approval-memory confirmed working or failing on the IDE path, (c) licensing clarified for the local-LLM path, (d) a future Junie CLI release that adds an auth-free local mode.
