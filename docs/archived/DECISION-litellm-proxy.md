# Decision: LiteLLM proxy layer

**Date:** 2026-06-27
**Updated:** 2026-08-06 — oMLX route added; discovery criterion re-evaluated
**Updated:** 2026-08-02 — spiked and measured; status changed
**Status:** Available but **not** on the default path (`bin/litellm-proxy`)

## Context

We run strictly local, air-gapped open-weight models. Each runtime (LM Studio,
Ollama, mlx_lm.server) has its own model list file (`models.txt`,
`models-ollama.txt`, `models-mlx.txt`) and its own adapter code.

LiteLLM is a Python proxy that presents a single OpenAI-compatible API in front
of multiple backends. It runs locally and routes requests to whichever runtime
is serving the model.

## Decision

Ship it as an **optional** component, and do not route adapters through it by
default. The 2026-08-02 spike showed the thing we most wanted from it —
collapsing per-runtime adapters — did not actually require it.

## What the spike measured

Verified end-to-end: aider → LiteLLM (`:4444`) → LM Studio, real edit applied.
Wildcard routes (`lms/*`, `ollama/*`, `mlx/*`, `omlx/*`) pass the model id
through, so no model needs listing individually. Re-verified 2026-08-06 through
the `omlx/` route: a completion and a native tool-call both round-tripped.

**RAM: ~270 MB RSS.** Negligible next to the KV-cache budget, so it is not a
concern even on a 32 GB machine — `BENCH_CONTEXT`/`BENCH_PARALLEL` dominate by
orders of magnitude. RAM was never the reason to hesitate.

**Packaging is fragile.** A plain `uvx litellm` dies at startup with
`ModuleNotFoundError: proxy_server`; litellm under-constrains fastapi and the
default resolution imports a symbol newer fastapi dropped. `bin/litellm-proxy`
pins `--python 3.12 --with 'fastapi<0.116'` to work around this. Expect this pin
to need revisiting on upgrade.

## Revisit criteria, re-evaluated

### 1. Simplify model configuration — *still open, still the best reason*

Three `models*.txt` files with runtime-specific ids remain the real duplication.
A canonical-name → runtime mapping is the strongest remaining argument for the
proxy. Not attempted in the spike.

### 2. Reduce adapter count — **resolved without LiteLLM**

The original premise was wrong in two ways:

- **The endpoint boilerplate was already solved.** `bin/bench` sets
  `LMS_BASE_URL`/`LMS_API_KEY` to whichever runtime is active, so an adapter
  reading those works under all three. The `-lms`/`-ollama`/`-mlx` variants were
  duplicating a URL that `bin/bench` already supplied.
- **LiteLLM does not normalize what actually differs.** It translates
  `tool_calls` schemas between providers and can prompt-inject functions for
  models with no native support — but it does *not* repair a model that emits
  malformed/text tool-calls (that remains `bin/tool-call-proxy`'s job), and it
  has no visibility into aider's `--edit-format` (`whole` vs `diff`), which is a
  *prompting* choice inside aider, above the HTTP layer.

The aider adapters were unified into one `adapters/aider.sh` branching on
`$RUNTIME`, with no proxy involved. Any remaining per-runtime flags
(`--edit-format`, `--model-metadata-file`) are tool-side config LiteLLM cannot
touch, so they would survive a proxy migration unchanged.

### 3. Model discovery — **resolved for the proxy, not for the agents**

The proxy side works. With `check_provider_endpoint: true` the proxy queries each
backend live, so `bin/litellm-proxy --models` is a true union of what the local
runtimes serve — measured 2026-08-06: 12 lms + 11 ollama + 11 omlx, and `mlx/`
correctly empty while mlx_lm.server was down. `bin/doctor` reports the per-route
counts for the same reason.

That does not help the agents, and the proxy cannot make it help them. Most
coding CLIs never call `/v1/models` at all — they read a hand-maintained list
from their own config (see [MODEL-DISCOVERY.md](MODEL-DISCOVERY.md), measured the
same day). Routing them through LiteLLM would change *where* they send the
request, not *whether* they ask what exists. Discovery for those agents stays
`bin/agents-config`'s job.

So the remaining argument for the proxy is criterion 1 alone.

## Local-only constraint

`config-templates/litellm.yaml` lists **no** hosted providers and sets
`num_retries: 0` with no fallbacks, so a request whose backend is down fails
rather than rerouting (verified: a request to a dead mlx backend returns
`Fallbacks=None`, not a substituted model). This is load-bearing — a remote
fallback would leak sandbox prompts off-machine *and* silently grade a different
model than the result label claims. Telemetry is disabled in-config.

## Usage

```bash
bin/litellm-proxy          # foreground, port $LITELLM_PORT (default 4444)
bin/litellm-proxy --check  # verify reachable
bin/litellm-proxy --models # what each route currently resolves
```

`bin/doctor` reports the proxy only when it is running, since the default path
does not use it.
