# Decision: Replace LiteLLM with Olla

**Status:** Accepted
**Date:** 2026-09-28

## Context

LiteLLM has fronted all five local runtimes (lms, ollama, mlx, omlx, mtplx)
since 2026-08-02. It causes three recurring problems: it needs an access
token even for purely local clients like the chat interface; models
sometimes have to be synced by hand into its Postgres-backed
`store_model_in_db` store; and startup is slow and multi-step (Docker +
Postgres). `config.sh`'s comment "Auth requires pre-registering keys in
litellm's token database. For now, disable proxy" and the resulting
`LITELLM_PROXY_MODE=0` default are the clearest evidence — auth has shipped
disabled for most of LiteLLM's life. The 2026-09-28 spike
([docs/DECISION-proxy-olla.md](DECISION-proxy-olla.md)) evaluated
[Olla](https://github.com/thushan/olla) v0.0.29 as a replacement.

## Decision

Adopt Olla as the proxy layer. It fixes all three pain points directly: no
auth token needed locally, automatic model discovery with no manual sync,
and a single static binary that's ready in ~0.8s with no Docker/Postgres.
**Code migration is a follow-up, not done yet** — this decision covers the
proxy choice only.

## Time with LiteLLM (retrospective)

Introduced 2026-08-02 (`2c51e2d`) as an optional local-only proxy, then made
mandatory 2026-08-23 (`f077698`) when all adapters were unified through it
and the per-runtime `--runtime` flag was removed. That consolidation is what
it did well — by 2026-08-30 (`2b1df3c`) all 21 adapters were smoke-passing
against it, and it also serves Anthropic's `/v1/messages` endpoint.

The problems accumulated alongside that win: a Docker-backed proxy with
`store_model_in_db` (2026-08-22, `7adfccf`) traded a plain binary for a
container + database; models still needed manual/ad-hoc sync for MTPLX and
oMLX (2026-09-05 to 2026-09-09); a PII guardrail was added and reverted
within days (2026-08-29, `abe97dd`/`4a3d6f9`); auth/key handling needed
repeated fixes without ever reaching a state safe to enable for local use
(e.g. `923b33b`, 2026-09-12); adapters needed an `openai/` prefix wrapper
just to talk to LiteLLM's bundled clients (2026-09-16, `f3ed7fb`); and as
recently as 2026-09-21 (`e7927b9`) the Postgres volume mount needed fixing
for a pg18 upgrade. Olla gets the same unification (endpoint, discovery,
native Anthropic support) without the Docker/Postgres/auth overhead.

## Consequences

**Removed (follow-up, not done yet):** `bin/litellm-proxy`,
`config-templates/litellm.yaml` and `litellm-hooks`, `omp-litellm-config.yml`,
the `LITELLM_*`/`DATABASE_URL`/`LITELLM_PG_*` vars in `config.sh`,
LiteLLM-specific adapter routing, and the Postgres container.

**Gained:** no local auth requirement, automatic model discovery, ~0.8s cold
start, and a native `/olla/anthropic/v1/messages` route.

**Known caveats (from the spike, unresolved):** MTPLX needs a hand-written
custom Olla profile (the generic `openai-compatible` profile's capability
patterns are tuned for cloud-shaped `gpt-*` names and silently drop
`mtplx-*` models from tool-call/Anthropic routing); opencode-style adapters
that read a static provider-config file need their own config-sync step
re-pointed at Olla; model-ID collisions across backends under
`routing_strategy: strict` were not exercised in the spike.

The `bin/litellm-proxy` → `bin/olla-proxy` migration, `config.sh` variable
changes, and the opencode config-sync are sketched in
docs/DECISION-proxy-olla.md's "Migration sketch" but not implemented.

## References

- [docs/DECISION-proxy-olla.md](DECISION-proxy-olla.md) — spike, test
  evidence, migration sketch
- [docs/runtimes/olla.md](runtimes/olla.md)
- [docs/runtimes/litellm.md](runtimes/litellm.md)
- [docs/archived/DECISION-litellm-proxy.md](archived/DECISION-litellm-proxy.md) — superseded
