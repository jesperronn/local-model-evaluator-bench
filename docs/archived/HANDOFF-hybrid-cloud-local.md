# Handoff: explore a hybrid cloud + local model setup

**Date:** 2026-08-09
**Goal:** not a fix — this is a discussion starting point for a new thread.
Explore whether "hard" tasks can route to cloud models (OpenAI, Anthropic, or
GitHub Copilot's cloud) while "easy"/subagent-spawned tasks stay on local
models (LM Studio / Ollama / MLX / oMLX), and what that would take to wire up
in this repo.

## Why this exists

This came out of a side conversation about running Claude Code itself with a
mix of cloud (opus/sonnet) and local (haiku → Ornith) models via a LiteLLM
front. That's a Claude-Code-specific use case; the user's actual ask is
broader — a general hybrid routing setup for *this benchmarking harness*,
where subagent/easy work stays local and harder tasks can escalate to cloud.

## This conflicts with the repo's current premise — read this first

This project is currently built around a hard **local-only, air-gapped**
constraint, not a soft default:

- [DECISION-amp-cloud-only.md](DECISION-amp-cloud-only.md) rejected Amp
  specifically *because* it's cloud-only with no local endpoint override —
  "incompatible with this harness's air-gapped, local-model requirement."
- [DECISION-litellm-proxy.md](DECISION-litellm-proxy.md)'s own proxy config
  (`config-templates/litellm.yaml`) explicitly lists **no hosted providers**
  and sets `num_retries: 0` with no fallbacks, calling this "load-bearing — a
  remote fallback would leak sandbox prompts off-machine *and* silently grade
  a different model than the result label claims."
- My own memory of this project (saved from an earlier session) says: *never
  add cloud/hosted model providers; local runtimes only.*

None of that is a hard blocker — constraints get revisited — but it means
this isn't a small addition on top of existing plumbing; it's a premise
change. Worth deciding explicitly, in the new thread, whether this is:

(a) a **benchmarking-harness feature** (cloud models become bench-able
targets, evaluated on the same footing as local ones — raises the "leak
sandbox prompts off-machine" concern the litellm decision flagged), or

(b) a **meta/tooling concern** (the *agents that orchestrate the benchmark
runs* — e.g. Claude Code itself — use a hybrid backend, but the harness under
test stays local-only).

These have very different blast radii. (b) is much closer to the original
Claude Code opus/sontet+haiku question and doesn't touch this repo's core
constraint at all.

## Account-access findings from this session (don't re-derive these)

- **Anthropic API:** blocked. `console.anthropic.com` shows "Parent
  Organization 'Nine AS' is blocking new organization creation for domain
  nine.dk." This is an IT-admin-level lock, not something to route around.
  Either nine.dk already has API access under the existing Nine AS org
  (worth checking for an existing seat), or IT needs to unblock it.
- **OpenAI API:** self-serve path is open — no API key exists yet, and key
  creation requires a project first (Platform → Projects → Create → then
  create a scoped key). Untested whether billing/payment setup hits any
  further org-level block; that's the next thing to actually try, not assume.
- **GitHub Copilot cloud:** not checked yet this session. `adapters/`
  already has `copilot-lms.sh` / `copilot-mlx.sh` / `copilot-ollama.sh` /
  `copilot-omlx.sh` (all local-backend variants) — worth checking whether
  Copilot's own CLI/API supports a genuine cloud-hosted-model path distinct
  from those, and whether the user's existing Copilot subscription/seat
  covers API-level access (same subscription-vs-API-key distinction that
  applies to Anthropic and OpenAI).

## Relevant existing plumbing to build on, not duplicate

- `config.sh` already has a `LITELLM_*` block and `bin/litellm-proxy` fronting
  the four local runtimes with wildcard routes (`lms/*`, `ollama/*`, `mlx/*`,
  `omlx/*`). Adding cloud routes to the *same* proxy is the natural
  extension point — but see the "no hosted providers" constraint above before
  touching `config-templates/litellm.yaml`.
- `bin/agents-config` / `bin/bench` / `bin/smoke` are the current
  local-only entry points; any hybrid routing needs to decide whether it
  lives at this layer (harness picks cloud vs local per task) or one level up
  (a calling agent like Claude Code decides, and this repo stays untouched).
- `docs/PLAN-COPILOT-launcher.md` and `docs/AGENT-SELECTION.md` likely have
  relevant prior thinking on tool/model selection — skim before designing new
  selection logic from scratch.

## Open questions for the new thread

1. Scope: (a) or (b) above, or genuinely both?
2. If (a): what decides "hard" vs "easy"? Task-type heuristic, explicit flag
   per bench run, or a judge/router model?
3. If (a): how does this square with the "no sandbox-prompt-leak" constraint
   that killed hosted providers in the litellm decision? Does bench get an
   explicit `--allow-cloud` opt-in per run, logged distinctly from local
   results, so cloud-graded results are never silently conflated with local
   ones?
4. Which cloud path is actually available first — Nine AS unblocking
   Anthropic, or self-serve OpenAI project+billing? That probably determines
   which gets prototyped first.
5. Does this want its own `DECISION-hybrid-cloud-local.md` once scoped, given
   the two existing DECISION docs it directly contradicts/extends?

## Non-goals for this handoff

- Not deciding (a) vs (b) — that's the new thread's first job.
- Not touching `config-templates/litellm.yaml` or any adapter yet — no code
  changes should happen before the scope question above is answered, since
  the answer changes what "done" even looks like.
- Not resolving the Nine AS Anthropic org block — that's an IT ticket, not
  something fixable from this repo.
