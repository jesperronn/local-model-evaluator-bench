# Decision: PII masking gateway for local runs (deferred)

**Status:** Deferred — investigate again when the candidates mature
**Date:** 2026-10-19 (research as of 2026-10-08)

## Context

We want an optional step that masks personally identifiable information
(PII) before prompts reach a local model, so benchmark or chat traffic can
be run with redaction switched on when needed. Two earlier attempts:

- **Presidio via LiteLLM** (`abe97dd`, removed in `4a3d6f9`, 2026-08-29).
  The built-in guardrail never booted: wrong config schema, and a hard
  dependency on `presidio-analyzer`/`presidio-anonymizer` containers that
  the repo never started. See
  [DECISION-pii-guardrail-presidio.md](archived/DECISION-pii-guardrail-presidio.md).
- **Custom LiteLLM hook** — proposed in the same archived doc, never built.

With LiteLLM being replaced by Olla ([DECISION-replace-litellm-with-olla.md](DECISION-replace-litellm-with-olla.md)),
a LiteLLM hook is no longer the right place for this. The PII step has to
sit in front of Olla as a separate process.

## Candidates

### PrivAiTe (leading candidate)

[github.com/crp4222/PrivAiTe](https://github.com/crp4222/PrivAiTe), v0.7.2,
BSD-3, released 2026-10-08 (about 25 releases since May; pin a version).

- Runs locally as an OpenAI-compatible proxy at `localhost:8400/v1`, as a
  Docker image or a pip package.
- Also offers a gateway mode for Claude Code and Codex (Codex marked beta),
  a LiteLLM guardrail, and an Open WebUI filter.
- Detection uses Presidio plus OpenAI's open privacy-filter model. The
  default `onnx` preset is recommended. A `light` preset runs Presidio alone
  with no model download, but misses some names.
- Reversible placeholders such as `<PERSON_1>` are kept in memory per
  request and restored in replies, including streamed ones. Card numbers
  and secrets are redacted permanently.
- Scans tool-call arguments.

### Other options

- **PasteGuard** — Presidio-based, with a mask mode and a route-to-local
  mode. About 600 stars.
- **Build our own** — a Presidio-based proxy plus a placeholder vault.
- **Bifrost, guardrail-rs, and similar gateways** — have PII features but
  are not local-first replacements for Olla.

### Olla

Per the 2026-10-08 research, Olla's README lists no middleware, guardrails,
content filtering or plugin/hook system. It cannot host the PII step
itself, so the filter must run as its own process in front of it.

## Caveats

- **Recall:** about 85% span recall. In tool-call JSON about 15% of PII is
  missed. Treat this as risk reduction, not a guarantee.
- **Pseudonymization, not anonymization.** It does not by itself meet GDPR
  or HIPAA requirements.
- **Network exposure:** gateway mode binds `0.0.0.0` by default with no
  auth. It must be bound to localhost.
- **Scope gap:** in gateway mode it does not scan the `system` /
  `instructions` fields.
- **Benchmark validity:** masking changes what the model sees. Masked runs
  are not comparable to unmasked runs, so results must be labeled, or
  masking kept out of scored runs.
- **Model download:** the `onnx` preset fetches about 900 MB on first run.
  Note this in setup docs. It is a one-time fetch, and the runtime stays
  local, which fits the local-models-only rule.

## Proposed shape (not built)

    agent harness → PrivAiTe (localhost, toggleable) → Olla → local runtime

Off by default. Enabled per run, the same way the removed `--guardrails`
flag worked.

## Open items

1. **Anthropic path.** Adapters reach Olla at `/olla/anthropic/v1/messages`.
   Not confirmed that PrivAiTe's gateway mode handles that format for
   generic clients. Needs a smoke test against a localhost-bound instance.
2. **Benchmark labelling.** Decide how masked runs are recorded and whether
   they are excluded from comparisons.
3. **Recall acceptance.** Decide what leak rate is acceptable for the use
   case before enabling it on real data.
4. **Version pinning and maintenance.** PrivAiTe releases quickly. Pick a
   version after a smoke test and re-check on each upgrade.

## Revisit when

- PrivAiTe's gateway mode is confirmed working with Olla's Anthropic
  endpoint, or a different candidate clearly beats it.
- Olla gains a middleware or hook point, which would remove the need for a
  separate process.
- Recall figures are confirmed on our own data, not only the README's
  numbers.
