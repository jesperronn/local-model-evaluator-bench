# Continue.dev (Agent mode)

Category: [IDE extensions / plugins](README.md) · Index: [vscode.md](vscode.md) / [intellij.md](intellij.md) · See also: [tools/continue.md](../tools/continue.md) (CLI-headless feasibility — separate concern)

## Quick verdict

| Field | Value |
|-------|-------|
| **Recommended for** | nothing, currently — see hard-gate failure below |
| **Status** | **avoid** (disqualified on approval memory) |
| **One-line why** | Required approving every single agent action individually with no persisted "always allow," making it unworkable in practice — a direct, dated user finding, not a hypothetical. |

## Metadata

| Field | Value |
|-------|-------|
| **Extension id** | continue.continue |
| **IDE(s)** | VS Code and IntelliJ (same core) |
| **Version** | version at time of the approval-memory finding not recorded; re-test on current version before lifting the disqualification |
| **How it connects** | `~/.continue/config.json`; Ollama, LM Studio, and other OpenAI-compatible providers documented directly |
| **Last reviewed** | 2026-07-01 (web research + prior direct experience, undated to "a few months ago" as of this writing) |

## Automation feasibility

**Feasible, not yet built.** Continue now ships an official headless CLI, `cn` (`@continuedev/cli`), model-agnostic and open source. `cn -p "<prompt>"` runs non-interactively and only prints the final response — a direct fit for this repo's adapter pattern (see [`adapters/cline-lms.sh`](../../adapters/cline-lms.sh) as the template). Config is `~/.continue/configs/config.yaml`, same `provider: ollama` / LM Studio `apiBase` fields as the extension uses. **Next step:** write `adapters/continue-lms.sh` mirroring cline's structure. **Caveat:** same as Cline — a headless `cn` run bypasses the approval-prompt UI entirely, so it cannot confirm or refute the criterion-4 finding below; that remains a GUI-only check.

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ✅ | Local providers configured directly in `config.json`; no account required for that path. |
| 2 | True agentic loop | ✅ | Agent mode is a genuine multi-step tool-calling loop, not just chat. |
| 3 | Tool-call reliability w/ local models | ⚠️ | Falls back to system-message tools for models without native tool support, but open GitHub issues (2026) document Agent-mode tool-call parsing breaking against Ollama-streamed output, notably with Qwen3-Coder-class models. |
| 4 | Approval memory (hard gate) | ❌ **FAIL — disqualifying** | Direct user finding: every single action required individual approval with no memory of prior approvals across the session — "impossible to work with." This alone drops the plugin to avoid regardless of other scores. |
| 5 | Multi-file edits | ⚠️ | Not separately verified; likely functional in principle but untested given criterion 4 blocks practical use before it matters. |
| 6 | Codebase awareness | ✅ | Documented repo-indexing/context features. |
| 7 | Config transparency | ✅ | `~/.continue/config.json` is plain JSON, scriptable, inspectable. |
| 8 | Active maintenance | ✅ | Actively developed, cross-IDE. |
| 9 | IDE-native integration | ✅ | Native to both VS Code and JetBrains. |
| 10 | License/cost | ✅ | Open source; local-model path not seat-gated. |
| 11 | Excels on at least one runtime | ⚠️ | Documents Ollama and LM Studio both; open issues specifically call out Ollama-streamed tool-call breakage, so "excels" is not yet demonstrated on either — needs a fresh run to confirm. |

> Rule 1 from [EVAL-TEMPLATE.md](EVAL-TEMPLATE.md) applies directly here: criterion 4 failing overrides every ✅ above. Do not read the mostly-green table as "close to usable" — it isn't, until this is fixed.

## Pros
- Cross-IDE: one config, works in both VS Code and IntelliJ, if the blocking issue is ever resolved.
- Config is plain, transparent JSON — easy to inspect/version-control.
- No forced cloud account for the local-model path.

## Cons
- **Approval memory failure (blocking).** This is the entire reason the plugin is ranked "avoid" — everything else about it is reasonably competitive.
- Open GitHub issues on Agent-mode tool-call parsing breaking against Ollama-streamed output.
- Worth re-testing after a version bump specifically targeting the approval UX, since this reads as a fixable bug rather than an architectural limitation — don't treat "avoid" as permanent without a re-check.

## Runtime notes
Not currently demonstrable as "excelling" on either Ollama or LM Studio — the approval-memory bug makes any extended session impractical before runtime-specific quality differences even become observable. Re-test once criterion 4 is confirmed fixed.

## Manual eval log

| Date | Case | Pass/total | Approval-prompt behavior | Notes |
|------|------|:----------:|--------------------------|-------|
| ~2026-04 (undated, recalled) | ad hoc use, not a formal case | n/a | **Re-prompted for every single action, no persistence** | Direct experience — described as "impossible to work with" |

## Status
**2026-07-01** — avoid, disqualified on approval memory. Re-rank trigger: a version release explicitly addressing persisted approvals, followed by a fresh manual run confirming the fix. Until then, do not recommend for daily agentic use on either IDE.
