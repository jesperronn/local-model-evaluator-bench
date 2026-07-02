# Future Ideas

Backlog of ideas and tools not yet implemented. Not a plan, not a spec —
just a place to park things before they're scoped. Move an item to a
`PLAN-*.md` or into `docs/tools/` once it's actually being worked on.

## Tools / adapters to evaluate

- **Qwen** — add both as an agent adapter (CLI) and check the IntelliJ plugin
  variant. Note: `docs/tools/qwen-cli.md` already covers the Qwen Code CLI;
  confirm whether this is the same tool or a distinct one, and whether the
  IntelliJ plugin exposes a headless/CLI mode we can drive like the other
  adapters.

## Infra / architecture

- **Local LLM proxy** — unified proxy normalizing API calls across runtimes
  (LM Studio, Ollama, mlx_lm.server) so agents don't need per-runtime base
  URLs and model IDs. LiteLLM proxy is the leading candidate. See
  [DECISION-litellm-proxy.md](DECISION-litellm-proxy.md) (deferred until
  pain increases — revisit criteria are documented there).

## Tooling / workflow

- **Troubleshoot command** — formalize the current ad-hoc troubleshooting
  flow into a proper command/skill with clear borders vs. `doctor`,
  `investigate`, and `report`. See [PLAN-TROUBLESHOOT.md](PLAN-TROUBLESHOOT.md).

## Model backlog

- **qwen3.6-27b** — pending addition (GLM-4.7-Flash 30B already added,
  2026-06-28).
- **`gemma-4-26b-a4b`** — fails to load in LM Studio (bad download); needs
  re-download/investigation before it can be benched.

## Doc / tooling follow-ups

- **`claude --print`** — the eval path needs a logged-in `claude` CLI session;
  currently blocked on login, so hosted-Claude judge/agent runs via this path
  don't work headless yet.
- **Backfill card Quick verdict tables** — the Quick verdict table is mandatory
  per `docs/CARD-SPEC.md` but was 0/40 cards as of 2026-06-30. Run a
  `bin/fix-card` sweep across all cards to backfill it.
- **Extract `eval/questions.jsonl`** — `bin/eval-agent` and
  `docs/AGENT-EVAL-SUITE.md` are wired against `docs/QUESTION-SUITE.md`
  (A/B/F/G), but the model+judge calls are still stubbed and
  `eval/questions.jsonl` hasn't been extracted yet.
