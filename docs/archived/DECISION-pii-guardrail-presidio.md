# Decision: drop the built-in Presidio PII guardrail (removed 2026-08-29)

commit abe97dd ("feat: Add PII redaction guardrails via LiteLLM Presidio")
added a `guardrails:` block to [config-templates/litellm.yaml](../../config-templates/litellm.yaml) using litellm's
built-in Presidio integration. It never actually worked, and the proxy has
been unable to start with that config since the commit landed — it only kept
running because the container wasn't restarted until this was debugged.

## What was wrong

1. **Schema mismatch.** The block used a flat schema (`entities`,
   `score_thresholds`, `mask_operator` directly on the guardrail dict), but
   the installed `litellm-database:main-stable` image requires those fields
   nested under `litellm_params:` — `guardrail_registry.py`'s
   `initialize_guardrail` reads `guardrail["litellm_params"]`
   unconditionally and `KeyError`s otherwise (see [litellm guardrail registry](https://github.com/BerriAI/litellm/blob/main/litellm/proxy/guardrails/guardrail_registry.py)).

2. **Hard container dependency, no way around it.** Even with the schema
   fixed, litellm's presidio hook calls `validate_environment()`
   unconditionally at proxy startup — regardless of `default_on: false` — and
   hard-requires `PRESIDIO_ANALYZER_API_BASE` / `PRESIDIO_ANONYMIZER_API_BASE`
   pointing at running `presidio-analyzer`/`presidio-anonymizer` containers.
   `bin/litellm-proxy` only ever starts postgres + the litellm proxy
   container; no presidio containers exist anywhere in the repo (confirmed
   via `docker images`, `docker network inspect litellm-net`, and grep for
   `PRESIDIO_ANALYZER`/`presidio-analyzer`/`presidio-anonymizer` across
   `bin/` and `docs/`). So any `guardrails:` block referencing the presidio
   hook crashes the proxy on boot, whether or not the guardrail is enabled.

3. **The test never caught it.** `bin/guardrails-test-inline` only grepped
   `bin/litellm-proxy`'s source for function names and jq filter shapes — it
   never started an actual proxy, so the startup crash was invisible to it.

## What was removed

- The `guardrails:` block (already commented out) from
  [config-templates/litellm.yaml](../../config-templates/litellm.yaml).
- `cmd_guardrails`, `_get_guardrails_status`, the `guardrails` case in the
  command dispatch, and the guardrails line in `cmd_status` from
  [bin/litellm-proxy](../../bin/litellm-proxy).
- [bin/guardrails-test-inline](../../bin/guardrails-test-inline).

The corrected `litellm_params`-nested schema is preserved in git history if
this is revisited (see the commit on branch `agent-/elegant-benz-17ff2e`
touching `config-templates/litellm.yaml`).

## Alternatives to explore later

### Custom hook pattern (recommended)

If PII redaction is needed again, the pattern already used elsewhere in this
proxy for exactly this kind of "touch the request/response before it leaves"
problem is a custom `CustomLogger`-style hook wired in via `callbacks:` — see
[config-templates/litellm-hooks/strip_unsupported_tools.py](../../config-templates/litellm-hooks/strip_unsupported_tools.py), already
registered as `hooks.strip_unsupported_tools.proxy_handler_instance` in
[config-templates/litellm.yaml](../../config-templates/litellm.yaml).

The same shape works for anonymization: a pre-call hook
(`async_pre_call_hook`) redacts/tokenizes PII in the outbound request before
it reaches the backend model, and a matching post-call hook reverses it (or
just leaves it redacted) on the way back. This avoids the presidio-specific
container dependency entirely — the hook can call a local NER/regex-based
redactor in-process, or shell out to a locally-run detector, without litellm
itself needing to know about Presidio or validate any Presidio-specific env
vars at startup. Worth prototyping as
[config-templates/litellm-hooks/pii_redact.py](../../config-templates/litellm-hooks/pii_redact.py) if this becomes a priority.

### External libraries

- [PrivAiTe](https://github.com/crp4222/PrivAiTe) — Local Python library with
  custom recognizers and anonymizers for flexible PII detection and redaction
  without external containers. Explored in prior session "PrivAiTe integration
  for local setup" (2026-08-29).
