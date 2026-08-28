# Plan: A Practical Code-Review Skill

Status: investigation complete; implementation not started.

This plan combines three complementary sources:

- [Google Engineering Practices: Code Review](https://google.github.io/eng-practices/review/)
  supplies the review contract: design, functionality, complexity, tests,
  naming, comments, style, and documentation, with correctness and suitable
  reviewers taking priority over ceremony.
- [Qwen Code: `/review`](https://github.com/QwenLM/qwen-code/blob/main/docs/users/features/code-review.md)
  supplies a scalable execution model: effort levels, parallel review lenses,
  diff-size-aware sharding, finding verification, reverse audit, isolation,
  incremental review state, and optional PR comments or fixes.
- Installed local skills supply the current baseline: a reviewer dispatched
  against an explicit Git range and requirements, a task-scoped spec/quality
  gate, scoped re-review after fixes, and skeptical verification of incoming
  feedback.

## Survey: review capability already installed on this machine

Verified by inspecting the installed binaries and bundled prompts (2026-08-17),
not from documentation.

| Tool | Entry point | Topology | Notable mechanics worth stealing |
|---|---|---|---|
| **qwen** 0.21.12 | `/review [pr\|path] [--effort low\|medium\|high] [--comment] [--fix]` — bundled skill at `~/.npm-global/lib/node_modules/@qwen-code/qwen-code/bundled/review/SKILL.md` (1331 lines) | 9 steps; ~14 named roles (`0`, `1a/1b/1c`, `2`, `3a/3b/3c`, `4`, `5`, `6a/6b/6c`, `7`, `test-matrix`, `invariant-a/b/c`) + optional domain specialists | Prompts are built by a **deterministic CLI subcommand** (`qwen review agent-prompt --role`), never hand-copied; mandatory git **worktree** for PR review; **anchor-not-line-number** comment placement; separate **severity vs confidence**; a **recall rule** for finders vs a precision filter for verifiers; **coverage receipts** ("say what you walked"); build/test agent with a **mutation/test-efficacy probe** and merge-base attribution; **reverse audit** to convergence at high effort |
| **goose** 1.46.0 | `goose review [RANGE] [--files] [--instructions] [--dry-run]` | Rust-driven orchestrator, one `goose run` subprocess per check, 4 concurrent | Reviewers are **user-authored files**: `**/.agents/checks/*.md` (per-check `model:`, turn-limit, tool allowlist) plus `**/.agents/REVIEW.md` scoped overrides. **JSONL finding schema** (`severity`, `path`, `line_start/end`, `summary`, `check`) — machine-gradable out of the box. `--dry-run` prints the exact assembled prompt. Deliberately amp-compatible flags. |
| **codex** 0.147.0 | `codex review [PROMPT] [--uncommitted] [--base BRANCH]` | Single non-interactive review pass, custom instructions via arg or stdin | Cheapest possible baseline; scriptable, no orchestration to configure |
| **Claude Code** 2.1.234 | [`/code-review [target] [--effort] [--comment] [--fix]`](https://code.claude.com/docs/en/commands), plus `/simplify` and `/security-review` — bundled skill, **compiled into the binary** (`~/.local/share/claude/versions/2.1.234`), no on-disk `SKILL.md` to read or edit | find → adversarially verify → `ReportFindings` | Effort ladder low→max; findings carry `verdict: CONFIRMED\|PLAUSIBLE` separate from severity; `--fix` re-reports each finding as `fixed\|skipped\|no_change_needed`. Closed to modification — usable as a **comparison baseline**, not as a host for our lenses. |
| **omp** (oh-my-pi) | `/review` — bundled command (installed via `brew install omp`), prompts in the omp installation under `src/extensibility/custom-commands/bundled/review/` | Host computes a diff-size **agent count** (1 → 16) and tells the model to fan out `task(agent: "reviewer")` over file groups | Only installed tool that **scales reviewers to diff size in code, not by prompt**: `getRecommendedAgentCount` (<100 lines or ≤2 files → 1; <500 → 2; <2000 → ≤4; <5000 → ≤8; else ≤16), grouped by locality (tests with their impl). Diff is **injected** into the prompt with an explicit "NEVER re-run git diff"; oversized diffs degrade to per-file previews with a stated budget. Findings are a **typed schema** (`title`, `body`, `priority` P0–P3, `confidence` 0–1, `file_path`, `line_start/end`) streamed as incremental `yield` sections rather than a tool call; verdict is `overall_correctness` + confidence. Ships a second `security-reviewer` agent and pins `model: "@slow"`. See [tools/omp.md](tools/omp.md); upstream [can1357/oh-my-pi](https://github.com/can1357/oh-my-pi). |
| **hermes** | builtin skill `github-code-review` | Single skill, GitHub-scoped | PR-comment plumbing only |
| **opencode** 1.18.18 | `opencode github`, `opencode pr <n>`; agents `plan`/`explore`/`general` | No dedicated review agent shipped | Custom agents are easy to add; PR checkout helper exists |
| **aider** 0.86.2, **shai**, **cline/continue** | none | — | No review feature; usable only as generic diff-reading runners |
| shared skills in `~/.agents/skills/` | `requesting-code-review`, `receiving-code-review`, `verification-before-completion` | Prompt protocols | Reviewer gets crafted context, never session history; verify feedback before implementing |

Four structural lessons from the survey:

1. **goose, omp and Claude Code converge on the same schema shape** (severity or
   P0–P3 + path + line range + summary/scenario, one object per finding). omp and
   qwen both carry a numeric confidence separate from severity; qwen adds an
   anchor snippet. A single schema can drive all of them.
2. **goose's `.agents/checks/*.md` is the only tool-native, file-based extension
   point on this machine** — a check written once is dispatched in parallel with
   a per-check model. That makes it the natural place to prototype lenses, and
   it directly serves this repo's purpose (does a 2-bit local model make a
   usable reviewer?).
3. **omp shows the cheap version of qwen's sharding**: a 15-line host function
   turns diff size into an agent count and hands the model a pre-captured diff.
   Diff-size routing (P1 task 10) does not need qwen's plan/manifest machinery
   to start.
4. **qwen's real innovation is not the agent count** — it is that prompts,
   anchors, and coverage checks are computed by deterministic code around the
   model. Every place qwen's own design notes cite a measured failure, the fix
   was to move work out of the model, not to add an agent.

## Design conclusion

Build a staged review skill around one trustworthy review record, not around a
fixed number of agents. Start with a single deterministic review contract and
one or two independent lenses; add parallelism only after the findings can be
verified and measured. The default output should be a human-readable report
with file/line evidence, failure scenarios, severity, confidence, and a clear
verdict. Posting comments or applying fixes should remain explicit opt-ins.

The process should distinguish:

1. **Review quality** — did we find real, important issues?
2. **Review coverage** — did we inspect the relevant code and invariants?
3. **Process safety** — did we preserve the author’s tree and avoid acting on
   unverified findings?
4. **Cost/latency** — was the depth appropriate for the change?

## Prioritized implementation tasks

### P0 — Establish the smallest useful, safe review loop

0. **Pick the host and keep the prompt portable.**
   Prototype in `goose review` — it is the only installed tool with a
   file-based, parallel, per-check-model extension point (`.agents/checks/*.md`,
   `.agents/REVIEW.md`), and `--dry-run` makes the assembled prompt inspectable
   and diffable. Keep every lens as a plain Markdown file with a frontmatter
   header so the same text can be fed to `codex review -` on stdin and to a
   Claude Code skill without rewriting. Do not fork qwen's CLI; borrow its
   mechanics.

1. **Define the review contract and input scope.**
   Specify local diff, commit range, file, and PR targets; resolve the base
   correctly; capture requirements/plan, repository rules, test commands, and
   changed-file metadata. Define what counts as in-scope and what the reviewer
   must not mutate.

2. **Create a canonical finding schema.**
   Start from goose's JSONL line format (`severity`, `path`, `line_start`,
   `line_end`, `summary`, `check`) — it already parses and it is what the
   installed orchestrator emits — and extend it.
   Require: stable ID, severity, confidence, file/line, failure scenario,
   violated requirement or invariant, impact, suggested remedy, and status.
   Add explicit `needs-human-review` and `out-of-scope` states so uncertainty
   is visible rather than silently discarded.

3. **Implement one baseline reviewer.**
   Review the diff against requirements and the Google dimensions: design,
   functionality, complexity, tests, naming/comments/style, and documentation.
   Require evidence and a final `ready / needs fixes / cannot assess` verdict.
   Keep the existing local reviewer prompt as the initial compatibility target.

4. **Add verification before reporting blockers.**
   Run a second pass over every proposed Critical/Important finding. The
   verifier must trace the claimed failure scenario through the actual code,
   downgrade uncertain findings instead of deleting them, and identify false
   positives. This is the minimum quality gate before a verdict or external
   comment.

5. **Make isolation and side effects explicit.**
   Use a temporary worktree for PR/build/test review where possible. Make
   read-only review the default. Require separate explicit modes for posting
   comments and applying fixes; never apply an unverified finding silently.

6. **Add focused regression fixtures.**
   Build a small review corpus in this benchmark repo: real bugs, security
   issues, missing tests, false positives, scope misunderstandings, and
   cross-file regressions. Score detection, severity, evidence, and false
   positive rate rather than only whether the prose sounds plausible.

6b. **Benchmark reviewers the way this repo benchmarks coders.**
    The fixture corpus from task 6 is a bench case: run the same lens files
    across local models (`lms`/`mlx`/`ollama`) and across the four hosts
    (`goose review`, `codex review`, `qwen /review`, Claude Code
    `/code-review`), and score precision, recall on seeded bugs, and wall time.
    This answers the question the repo exists to answer — the smallest local
    model that is a *useful reviewer* is probably not the same one that is the
    best coder.

7b. **Move work out of the model wherever qwen's design notes did.**
    Concretely: generate each lens prompt from one script rather than pasting
    variants; resolve comment positions from a quoted snippet rather than a
    model-asserted line number; compute the "did every changed file get a
    receipt" check in code; keep the exclusion criteria and the recall rule in
    the generated brief so they cannot be dropped in relaying.

### P1 — Improve coverage without multiplying noise

7. **Split the baseline into independent review lenses.**
   Start with three parallel lenses: correctness/data-flow, security, and test
   coverage. Add reuse/duplication, abstraction/complexity, consistency, and
   performance only when fixtures show a meaningful gap.

8. **Add a coverage receipt.**
   Each lens records which files/hunks/symbol edges it inspected. Do not issue
   “no blockers” if a changed area has no accountable review receipt.

9. **Add a cross-file and removed-behavior pass.**
   Trace changed symbols to callers and added fields to readers. For deleted or
   replaced code, state which invariant it enforced and where the replacement
   re-establishes it. These are high-value Qwen ideas that are not fully
   covered by the current local task reviewer.

10. **Add change-size-aware routing.**
    Use a cheap single pass for small/local changes, the parallel lenses for
    normal changes, and territory-by-dimension sharding for large diffs. Split
    only at hunk or top-level declaration boundaries and preserve coverage
    receipts.

11. **Add an undirected reverse audit.**
    After findings are verified, ask fresh reviewers to look for what all prior
    passes missed, using attacker, on-call, and maintainer perspectives. Stop
    after a bounded number of dry rounds and report the cap reached.

### P2 — Make the process operationally useful

12. **Introduce effort levels and cost controls.**
    Define low/medium/high modes with clear guarantees. Low may be fast and
    explicitly unverified; medium verifies findings and runs relevant tests;
    high adds broad parallel coverage and reverse audit. Record model calls,
    elapsed time, and validation commands.

13. **Integrate repository-specific rules.**
    Load `AGENTS.md`, `docs/WORKFLOW.md`, test/lint commands, and tool-specific
    conventions. Keep project policy separate from generic reviewer prompts.
    For this repository, preserve the no-auto-approve policy and use the
    existing result/report commands for evaluation evidence.

14. **Add incremental review state.**
    Cache the reviewed head and finding IDs only for verified high-quality
    reviews. On re-review, focus on new commits and unresolved findings while
    retaining a full-review escape hatch. Never let an unverified low-effort
    pass suppress a later high-effort review.

15. **Support explicit delivery modes.**
    Produce terminal/Markdown reports first. Add optional PR inline comments
    only for high-confidence findings, with duplicate suppression and CI-status
    checks. Add `--fix` only after the fix-accounting model can record fixed,
    skipped, and no-change-needed outcomes.

16. **Measure and tune the review system.**
    Track true positives, false positives, missed seeded bugs, severity
    calibration, duplicate rate, coverage receipts, cost, and time-to-verdict.
    Revisit agent decomposition from evidence; do not adopt a 14-agent shape
    as a goal in itself.

### P3 — Future extensions

17. **Domain-specialized finders.** Generate or select narrow finders for
    domains such as shell/process handling, concurrency, migrations, auth,
    parsers, and network retries.

18. **Reviewer selection and model routing.** Choose reviewers by repository
    area, change type, model strength, latency, and historical precision.

19. **Human collaboration features.** Support inline discussion, adjudication
    of disputed findings, reviewer feedback, and learning from accepted or
    rejected findings without changing the code automatically.

## Proposed first milestone

Implement P0 tasks 0–6b as a review skill prototype and benchmark it on a
curated fixture set. The milestone is complete when it can review a local Git
range in an isolated/read-only manner, produce schema-valid findings with
evidence and scenarios, verify blocker findings, run the relevant checks, and
show measured precision/recall and cost on the fixture corpus.

Do not implement the full Qwen topology before this milestone. Parallel
reviewers amplify both useful coverage and systematic false positives; the
verification layer and evaluation corpus must come first.

## Local skill mapping

| Local capability | Reuse | Gap to close |
|---|---|---|
| `requesting-code-review` | Explicit Git range, requirements, severity, verdict | No finding schema, confidence, verification, or coverage receipt |
| `subagent-driven-development` task reviewer | Task-scoped spec compliance + quality gate | Designed for implementation tasks, not general PR topology |
| `subagent-driven-development` re-review | Scoped finding-by-finding fix verification | Needs a reusable persisted finding record |
| `receiving-code-review` | Verify before implementing; technical pushback; test each fix | Primarily a response protocol, not a review engine |
| `finishing-a-development-branch` | Test gate and integration safety | Review is not its central concern |

## Decisions to preserve

- Google’s quality dimensions are the review baseline, not a claim that every
  stylistic preference is merge-blocking.
- Every actionable finding needs a concrete failure scenario and evidence.
- Severity and confidence are separate axes.
- Large diffs need a coverage strategy, not merely more agents reading the
  same whole diff.
- Human review remains the authority for ambiguous or low-confidence findings.
- Posting comments, editing the tree, merging, and pushing are separate,
  explicit actions.
