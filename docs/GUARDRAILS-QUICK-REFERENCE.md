# Guardrails Quick Reference

## Start here

```bash
# Start proxy
bin/litellm-proxy start

# Enable guardrails
bin/litellm-proxy guardrails on

# Check status
bin/litellm-proxy status

# Disable guardrails
bin/litellm-proxy guardrails off
```

## Commands

| Command | Effect | Output |
|---------|--------|--------|
| `guardrails on` | Enable PII detection | `guardrails: enabled (presidio-pii)` |
| `guardrails off` | Disable PII detection | `guardrails: disabled` |
| `guardrails status` | Show current state | `guardrails: on (presidio, PERSON\|EMAIL_ADDRESS...)` or `guardrails: off` |
| `guardrails config` | Show full config (JSON) | JSON with all guardrail settings |

## Status output format

When guardrails are **OFF**:
```
litellm proxy: up at http://127.0.0.1:8000/v1
  db: connected
  guardrails: off
postgres: up (litellm-postgres, port 5432)
```

When guardrails are **ON**:
```
litellm proxy: up at http://127.0.0.1:8000/v1
  db: connected
  guardrails: on (presidio, PERSON|EMAIL_ADDRESS|PHONE_NUMBER|CREDIT_CARD)
postgres: up (litellm-postgres, port 5432)
```

## What it detects

When enabled, guards against:
- **PERSON** — person names
- **EMAIL_ADDRESS** — email addresses
- **PHONE_NUMBER** — phone numbers
- **CREDIT_CARD** — credit card numbers

## Key points

- No proxy restart needed — changes apply immediately
- Works with or without `$LITELLM_MASTER_KEY`
- Proxy must be running (start with `bin/litellm-proxy start`)
- Uses LiteLLM Admin API internally

## Verify it works

```bash
# Inline validation (no running proxy needed)
./test-guardrails-inline.sh

# Full integration tests (requires running proxy)
bin/litellm-proxy start
./test-guardrails.sh
```

## Scripting examples

```bash
# Enable only for specific tests
bin/litellm-proxy guardrails on
pytest tests/pii-sensitive/
bin/litellm-proxy guardrails off

# Check if enabled before running
STATUS=$(bin/litellm-proxy guardrails status)
if [[ "$STATUS" == *"on"* ]]; then
  echo "PII detection active"
fi

# Show entities being protected
bin/litellm-proxy guardrails config | jq '.[].entities'
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "check proxy is running" | Run: `bin/litellm-proxy start` |
| Command times out | Proxy may be slow, wait and retry |
| State doesn't change | Verify with: `bin/litellm-proxy guardrails config` |

## See also

- Full docs: `docs/GUARDRAILS.md`
- Implementation details: `GUARDRAILS-IMPLEMENTATION.md`
