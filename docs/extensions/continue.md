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

**Built and verified 2026-07-01.** Continue's official headless CLI, `cn` (`@continuedev/cli`, `npm install -g @continuedev/cli`), is wired into this repo as [`adapters/cn-lms.sh`](../../adapters/cn-lms.sh) — named `cn`, not `continue`, because `bin/bench` resolves adapters via `command -v "$adapter"` and `continue` collides with the bash builtin of that name. The adapter generates a per-run `config.yaml` pointing `provider: openai` at `$LMS_BASE_URL`/`$MODEL_ID`, then runs `cn --config <file> -p --auto --silent "<prompt>"` (headless print-and-exit, auto-approve all tools, strip `<think>` tags).

Verified end-to-end via `bin/bench --cases smoke-00-hello,smoke-01-edit-file,smoke-02-numbers --agent cn --model qwen/qwen3.6-35b-a3b --runtime lms`: **6/6 pass, 9.7s avg**.

**Full case-set run (2026-07-01), `qwen/qwen3.6-35b-a3b`, `bin/bench --agent cn --runtime lms`:**

| Case | Result | Time |
|------|--------|-----:|
| bash-01-topwords | 4/4 | 123s |
| js-01-slugify-bug | 4/4 | 47s |
| js-02-debounce-feature | 4/4 | 75s |
| js-03-multifile-cache | 5/5 | 124s |
| js-04-multifile-rename | 3/3 | 41s |
| js-05-multiselect-filter | 5/5 | 119s |
| js-06-lint-and-test (self-verify) | 4/4 | 181s |
| ts-01-groupby | 3/3 | 93s |

**8/8 cases, 100%, including both multi-file cases (js-03, js-04) and the self-verify case (js-06).**

**Caveat unchanged:** `--auto` bypasses the approval-prompt UI entirely, so this measures the headless agent loop's accuracy/speed only — it neither confirms nor refutes the criterion-4 (approval memory) finding below, which is specific to the GUI extension's interactive flow. Next: run other models through `bin/bench --agent cn` to build out a per-model comparison, same as any other adapter.

## Criteria scorecard

| # | Criterion | Verdict | Evidence / notes |
|---|-----------|:-------:|-------------------|
| 1 | No mandatory cloud login | ✅ | Local providers configured directly in `config.json`; no account required for that path. |
| 2 | True agentic loop | ✅ | Agent mode is a genuine multi-step tool-calling loop, not just chat. |
| 3 | Tool-call reliability w/ local models | ✅ (headless CLI, LM Studio) | 8/8 measured pass via the `cn` headless CLI against LM Studio + qwen3.6-35b-a3b, including multi-file and self-verify cases. Open GitHub issues still document Agent-mode tool-call parsing breaking against **Ollama-streamed** output specifically — treat as runtime-specific, not disproven, until re-tested on Ollama. |
| 4 | Approval memory (hard gate) | ❌ **FAIL — disqualifying** | Direct user finding: every single action required individual approval with no memory of prior approvals across the session — "impossible to work with." This alone drops the plugin to avoid regardless of other scores. |
| 5 | Multi-file edits | ⚠️ | Not separately verified; likely functional in principle but untested given criterion 4 blocks practical use before it matters. |
| 6 | Codebase awareness | ✅ | Documented repo-indexing/context features. |
| 7 | Config transparency | ✅ | `~/.continue/config.json` is plain JSON, scriptable, inspectable. |
| 8 | Active maintenance | ✅ | Actively developed, cross-IDE. |
| 9 | IDE-native integration | ✅ | Native to both VS Code and JetBrains. |
| 10 | License/cost | ✅ | Open source; local-model path not seat-gated. |
| 11 | Excels on at least one runtime | ✅ | **Measured pass** — 8/8 (100%) via the headless CLI against LM Studio. That alone satisfies the bar; Ollama not separately confirmed and has open issues reported. |

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
| ~2026-04 (undated, recalled) | ad hoc use, not a formal case | n/a | **Re-prompted for every single action, no persistence** | Direct experience via the GUI extension — described as "impossible to work with" |
| 2026-07-01 | full case set (8 cases) | 8/8 | n/a — headless `cn` CLI, `--auto` bypasses prompts entirely | Automated via `bin/bench --agent cn`; confirms the agent loop itself is capable, isolates the blocker to the GUI's approval UX specifically |

## Status
**2026-07-01** — avoid **for the GUI extension**, disqualified on approval memory; the underlying agent is demonstrably capable (8/8 headless via `cn`). Re-rank trigger for the GUI: a version release explicitly addressing persisted approvals, followed by a fresh manual run confirming the fix. The headless `cn` CLI itself is already usable today for automated benchmarking — see [Automation feasibility](#automation-feasibility) — that verdict doesn't depend on the GUI fix.
