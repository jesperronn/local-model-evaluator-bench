# Decision: Amp (Sourcegraph) — skip, cloud-only

**Date:** 2026-06-27
**Status:** Skip — not a candidate for this harness
**Version checked:** `@sourcegraph/amp` 0.0.1782579189-g03e27d (npm latest)

## Context

Amp (ampcode.com) is a coding agent CLI from Sourcegraph. It was considered as
a new adapter candidate.

## Decision

Skip. Amp is cloud-only by design and incompatible with this harness's
air-gapped, local-model requirement:

- Requires `AMP_API_KEY`, obtained by signing in at ampcode.com/install.
- Inference is routed through Sourcegraph/Amp's backend to Anthropic + OpenAI
  — there is no documented `base_url` override, so it cannot be pointed at
  LM Studio (`http://localhost:1234/v1`) or Ollama.
- Threads auto-upload to ampcode.com/threads; local-only storage is an open
  community feature request, not something shipped.
- Headless mode (`amp -x "prompt"`) exists, but the model backend is still
  fixed to Amp's cloud — the CLI flag doesn't rescue it.

Same bucket as Cursor/Windsurf. Contrast with mini-swe-agent and OpenHands,
which accept arbitrary OpenAI-compatible endpoints via LiteLLM (see
[docs/tools/mini-swe-agent.md](tools/mini-swe-agent.md)).

## Revisit when

Sourcegraph ships a custom-endpoint / air-gap mode for Amp. Until then, skip
without re-investigating if it comes up again as an adapter candidate.

## Sources

- [Amp Owner's Manual](https://ampcode.com/manual)
- [Amp homepage](https://ampcode.com/)
- [@sourcegraph/amp on npm](https://www.npmjs.com/package/@sourcegraph/amp)
- [Sourcegraph air-gap issue (GitLab #197163)](https://gitlab.com/gitlab-org/gitlab/-/issues/197163)

See also: [AGENT-SELECTION.md](AGENT-SELECTION.md), [DECISION-litellm-proxy.md](DECISION-litellm-proxy.md).
