# LiteLLM Guardrails: PII Redaction & Safety Filtering

## 1. Overview

Guardrails are runtime safety mechanisms that scan model inputs and outputs for sensitive data before they reach language models or are returned to users. The local-model-evaluator-bench implements **Presidio-based PII detection** through LiteLLM's guardrails framework.

### What PII Redaction Does

When enabled, guardrails automatically:
- **Scan prompts** before sending to models (pre_call mode)
- **Detect sensitive entities** using confidence scoring (0.0–1.0 scale)
- **Apply masking** to detected PII, replacing sensitive values with `[REDACTED]` placeholders
- **Log detections** for audit and analysis
- **Accept/reject requests** based on configurable thresholds

### Why Local-Only Guardrails Matter

Unlike cloud-hosted model APIs (OpenAI, Anthropic cloud, etc.) that handle PII filtering server-side, local models have **no built-in safety layer**. Guardrails bridge this gap by:

1. **Keeping sensitive data on-machine** — PII never leaves your infrastructure
2. **Enabling compliance** — respect GDPR, HIPAA, and other data protection regulations
3. **Preventing prompt injection** — guard against data exfiltration attempts
4. **Supporting audit requirements** — log what sensitive data was detected and masked
5. **Custom control** — adjust thresholds and entity types to match your security policy

All guardrails processing happens **locally** in the LiteLLM proxy container, with no external API calls or third-party data transmission.

---

## 2. Configuration

Guardrails are configured through environment variables and YAML configuration files. Both the global proxy setting and per-run overrides are supported.

### Environment Variables (config.sh)

The following variables control guardrails behavior globally across all bench runs:

```bash
# Enable or disable guardrails globally (default: false)
export GUARDRAILS_ENABLED="${GUARDRAILS_ENABLED:-false}"

# Guardrails engine/provider (currently: presidio, or leave empty)
# Note: LiteLLM proxy controls the actual engine via config file
export GUARDRAILS_ENGINE="${GUARDRAILS_ENGINE:-}"

# Comma-separated list of PII entity types to detect
# Examples: PERSON,EMAIL_ADDRESS,PHONE_NUMBER,CREDIT_CARD
export GUARDRAILS_ENTITIES="${GUARDRAILS_ENTITIES:-}"

# Filter strictness level: lenient | moderate | strict
# Determines which score thresholds are applied
export GUARDRAILS_MODE="${GUARDRAILS_MODE:-moderate}"

# Minimum confidence score (0.0–1.0) for detecting entities as PII
# Higher = fewer false positives, more missed detections
# Lower = more sensitive but more false positives
export GUARDRAILS_SCORE_THRESHOLD="${GUARDRAILS_SCORE_THRESHOLD:-0.85}"
```

### LiteLLM Proxy Configuration (litellm.yaml)

The proxy configuration in `config-templates/litellm.yaml` defines detailed guardrail settings:

```yaml
guardrails:
  - guardrail_name: "presidio-pii"
    guardrail: "presidio"        # Presidio PII detector
    mode: "pre_call"             # scan inputs before sending to model
    default_on: false            # disabled by default; enable via bin/litellm-proxy
    
    entities:                    # Entity types to detect
      - "PERSON"
      - "EMAIL_ADDRESS"
      - "PHONE_NUMBER"
      - "CREDIT_CARD"
    
    score_thresholds:            # Confidence levels per entity
      PERSON: 0.5
      EMAIL_ADDRESS: 0.5
      PHONE_NUMBER: 0.5
      CREDIT_CARD: 0.5
    
    deny_list: []                # Optional: block specific values
    mask_operator: "MASK"        # How to redact: MASK, HASH, ENCRYPT, etc.
```

### Key Configuration Parameters

| Parameter | Type | Range | Default | Effect |
|-----------|------|-------|---------|--------|
| `default_on` | boolean | true \| false | false | Enable guardrails on proxy startup |
| `mode` | string | pre_call \| post_call | pre_call | Scan input prompts or output responses |
| `score_thresholds` | dict | 0.0–1.0 per entity | 0.5 | Confidence threshold to trigger masking |
| `mask_operator` | string | MASK \| HASH \| ENCRYPT | MASK | Redaction method |
| `deny_list` | list | string values | empty | Hardcoded values to always block |
| `entities` | list | PII type names | see Entity Types | Which entity types to detect |

### Modifying Guardrails Configuration

**To change thresholds or add entities:**

1. Edit `config-templates/litellm.yaml` in the `guardrails` section
2. Restart the proxy: `bin/litellm-proxy start` (or stop/start if already running)
3. Verify: `bin/litellm-proxy guardrails config`

**To enable/disable at runtime (no restart needed):**

```bash
bin/litellm-proxy guardrails on    # Enable
bin/litellm-proxy guardrails off   # Disable
```

---

## 3. Usage Examples

### Enable Guardrails Globally

Edit `config.sh` and set:

```bash
export GUARDRAILS_ENABLED="true"
```

Then restart the proxy:

```bash
bin/litellm-proxy start
bin/litellm-proxy guardrails on
```

All subsequent requests will scan for PII.

### Per-Run Override: Enable for One Test

Without modifying config.sh permanently:

```bash
# Enable guardrails for a specific test run
bin/litellm-proxy guardrails on

# Run your tests
pytest tests/security/

# Disable when done
bin/litellm-proxy guardrails off
```

Or in a script:

```bash
#!/bin/bash
set -e

# Ensure guardrails are on for this run
bin/litellm-proxy guardrails on

# Run sensitive tests
pytest tests/pii-redaction/
RESULT=$?

# Clean up
bin/litellm-proxy guardrails off

exit $RESULT
```

### Custom Entity Types

To detect only certain PII types (e.g., emails and phone numbers, but not names):

1. Edit `config-templates/litellm.yaml`:

```yaml
guardrails:
  - guardrail_name: "presidio-pii"
    entities:
      - "EMAIL_ADDRESS"
      - "PHONE_NUMBER"
      # Removed: PERSON, CREDIT_CARD
```

2. Restart the proxy:

```bash
bin/litellm-proxy start
```

3. Verify the config:

```bash
bin/litellm-proxy guardrails config | jq '.[0].entities'
# Output: ["EMAIL_ADDRESS","PHONE_NUMBER"]
```

### Adjust Confidence Thresholds

For higher sensitivity (catch more potential PII, accept more false positives):

```yaml
score_thresholds:
  PERSON: 0.3          # Lower threshold = more sensitive
  EMAIL_ADDRESS: 0.2
  PHONE_NUMBER: 0.2
  CREDIT_CARD: 0.2
```

For higher specificity (fewer false positives, accept missing some real PII):

```yaml
score_thresholds:
  PERSON: 0.9          # Higher threshold = fewer false positives
  EMAIL_ADDRESS: 0.95
  PHONE_NUMBER: 0.95
  CREDIT_CARD: 0.95
```

### Check Current Guardrails State

```bash
# Quick status
bin/litellm-proxy guardrails status
# Output: guardrails: on (presidio, PERSON|EMAIL_ADDRESS|PHONE_NUMBER|CREDIT_CARD)

# Full configuration as JSON
bin/litellm-proxy guardrails config | jq '.'
```

---

## 4. Trade-offs: Precision, Recall, and False Positives

Guardrails use statistical models (Presidio) that make probabilistic judgments. Understanding the trade-offs helps you configure them appropriately for your use case.

### Precision vs. Recall

- **Precision**: "When the guardrail says it found PII, is it actually PII?"
  - High precision = fewer false positives (fewer legitimate phrases blocked)
  - Achieved by raising `score_threshold` values

- **Recall**: "Does the guardrail find all the real PII?"
  - High recall = fewer false negatives (fewer real PII missed)
  - Achieved by lowering `score_threshold` values

You must choose: do you want to **block too much (high recall)** or **miss some PII (high precision)**?

### Typical False Positive Scenarios in Code Domains

Presidio's ML model was trained on general text and financial records, not code. In programming contexts, you may see false positives for:

| Pattern | Why | Example |
|---------|-----|---------|
| Variable/function names | ML thinks "Person" is a person's name | `class PersonDAO { }` detected as PERSON |
| Email-like strings | Pattern looks like email | `user@domain` in string literals |
| Comment metadata | Coincidental structure | `@author John` detected as PERSON + EMAIL |
| Test fixtures | Realistic sample data | Test credit card `4111-1111-1111-1111` |
| API paths | REST convention | `/api/people/123` partial match to PERSON |
| Code examples in docstrings | Embedded real-world examples | Documentation code samples |

### Recommended Thresholds by Use Case

| Use Case | PERSON | EMAIL | PHONE | CREDIT_CARD | Rationale |
|----------|--------|-------|-------|-------------|-----------|
| **Strict compliance** (HIPAA/GDPR) | 0.3 | 0.2 | 0.2 | 0.1 | Err on side of caution; accept false positives |
| **Moderate security** (default) | 0.5 | 0.5 | 0.5 | 0.5 | Balance false positives and false negatives |
| **Code-heavy workloads** | 0.8 | 0.85 | 0.8 | 0.95 | Reduce false positives in programming contexts |
| **Financial/healthcare** | 0.4 | 0.3 | 0.3 | 0.2 | Maximize detection in sensitive domains |

### Impact of False Positives on Workflow

High false-positive rates can:
- Block legitimate code submissions
- Require manual review/override overhead
- Break automated pipelines
- Frustrate users with legitimate but "PII-like" strings

Mitigate by:
1. Using higher thresholds for code-heavy benchmarks
2. Maintaining a `deny_list` of known false positives to whitelist
3. Combining with other validation (is it actually an email? Can we verify it's a real person?)
4. Logging and monitoring detections to tune over time

---

## 5. Entity Types Reference

Presidio detects the following PII entity types:

### PERSON

Detects: Person names, first names, last names, nicknames

```
Examples detected:
  "John Smith"
  "Alice"
  "Dr. Chen"

False positives in code:
  "PersonDAO" (class names)
  "getName()" (method names)
  "Person" (generic types)
```

**Typical threshold**: 0.5 (balanced) – 0.85 (code-heavy)

### EMAIL_ADDRESS

Detects: Email addresses matching standard patterns

```
Examples detected:
  "alice@example.com"
  "john.doe@company.co.uk"
  "support+tag@domain.org"

False positives:
  "user@localhost" in code examples
  "@author Jane" in docstrings
  "contact@domain" in documentation
```

**Typical threshold**: 0.5 (balanced) – 0.9 (code-heavy)

### PHONE_NUMBER

Detects: Phone numbers in various formats (US and international)

```
Examples detected:
  "+1 (555) 123-4567"
  "555.123.4567"
  "+44 20 7946 0958"
  "001-555-1234"

False positives:
  Version numbers ("1.0.555.1234")
  API keys with numeric patterns
  Test fixture numbers ("555-1234")
  Dates formatted ambiguously
```

**Typical threshold**: 0.5 (balanced) – 0.85 (code-heavy)

### CREDIT_CARD

Detects: Credit card numbers (PAN — Primary Account Number)

```
Examples detected:
  "4532-1488-0343-6467" (Visa)
  "5425233010103442" (Mastercard)
  "3782822463100051" (American Express)

False positives:
  Test credit cards in code ("4111111111111111")
  Long numeric sequences
  Part numbers or invoice IDs
```

**Typical threshold**: 0.5 (balanced) – 0.95 (code-heavy, strict)

### Other Entity Types (not enabled by default)

Additional entities Presidio can detect (edit `litellm.yaml` to enable):

- `IBAN` — International Bank Account Numbers
- `CRYPTO` — Cryptocurrency addresses
- `SSN` — US Social Security Numbers
- `DRIVER_LICENSE` — Driver's license numbers
- `PASSPORT` — Passport numbers
- `MEDICAL_LICENSE` — Medical license numbers
- `URL` — Web URLs
- `DATE_TIME` — Dates and timestamps
- `IP_ADDRESS` — IPv4 and IPv6 addresses

---

## 6. Troubleshooting

### Problem: Guardrails Status Shows "off" but I Enabled Them

**Diagnosis:**
```bash
bin/litellm-proxy guardrails status
# Output: guardrails: off
```

**Solution:**

1. Verify the proxy is running:
   ```bash
   bin/litellm-proxy status
   ```
   If not running, start it: `bin/litellm-proxy start`

2. Check the configuration was applied:
   ```bash
   bin/litellm-proxy guardrails config | jq '.[0].default_on'
   # Should output: true if enabled
   ```

3. Re-enable guardrails:
   ```bash
   bin/litellm-proxy guardrails off
   bin/litellm-proxy guardrails on
   ```

### Problem: "Check proxy is running" Error

**Diagnosis:**
```bash
bin/litellm-proxy guardrails on
# Error: failed to enable guardrails — check proxy is running (http://127.0.0.1:4444)
```

**Solution:**

1. Start the proxy:
   ```bash
   bin/litellm-proxy start
   ```

2. Wait a few seconds for it to initialize:
   ```bash
   sleep 2
   ```

3. Verify it's responsive:
   ```bash
   curl -s http://127.0.0.1:4444/v1/models | jq '.object'
   # Should output: "list"
   ```

4. Retry the guardrails command:
   ```bash
   bin/litellm-proxy guardrails on
   ```

### Problem: Too Many False Positives (Legitimate Text Blocked)

**Diagnosis:**
```bash
bin/litellm-proxy guardrails config | jq '.[0].score_thresholds'
# Output: { "PERSON": 0.5, "EMAIL_ADDRESS": 0.5, ... }
```

If you see false positives in code or test data:

**Solution:**

1. Raise the confidence thresholds in `config-templates/litellm.yaml`:
   ```yaml
   score_thresholds:
     PERSON: 0.75          # Increased from 0.5
     EMAIL_ADDRESS: 0.8
     PHONE_NUMBER: 0.8
     CREDIT_CARD: 0.9
   ```

2. Restart the proxy:
   ```bash
   bin/litellm-proxy start
   ```

3. Verify the new thresholds:
   ```bash
   bin/litellm-proxy guardrails config | jq '.[0].score_thresholds'
   ```

4. Test with a known false positive to confirm it's now allowed

### Problem: Real PII Not Being Detected (False Negatives)

**Diagnosis:**
```bash
# You know PII is present but guardrails didn't catch it
bin/litellm-proxy guardrails status  # shows on
# But sensitive data still appears in outputs
```

**Solution:**

1. Lower the confidence thresholds in `config-templates/litellm.yaml`:
   ```yaml
   score_thresholds:
     PERSON: 0.3           # Lowered from 0.5
     EMAIL_ADDRESS: 0.2
     PHONE_NUMBER: 0.2
     CREDIT_CARD: 0.2
   ```

2. Restart the proxy:
   ```bash
   bin/litellm-proxy start
   ```

3. Re-test. This will increase false positives but improve detection coverage.

### Problem: LITELLM_MASTER_KEY Authentication Errors

**Diagnosis:**
```bash
bin/litellm-proxy guardrails on
# Error: {"error": "Invalid or missing authorization"}
```

**Solution:**

If `$LITELLM_MASTER_KEY` is set, ensure it matches what the proxy expects:

1. Check the environment variable:
   ```bash
   echo $LITELLM_MASTER_KEY
   ```

2. Verify the proxy is using the same key:
   ```bash
   # Look for LITELLM_MASTER_KEY in proxy startup logs
   bin/litellm-proxy status
   ```

3. If keys don't match, either:
   - Unset the variable (for local single-user): `unset LITELLM_MASTER_KEY`
   - Or set both to the same value: `export LITELLM_MASTER_KEY="your-secret-key"`

4. Restart the proxy:
   ```bash
   bin/litellm-proxy start
   ```

### Problem: "Failed to update guardrails configuration"

**Diagnosis:**
```bash
bin/litellm-proxy guardrails on
# Error: failed to POST config — jq parse error
```

**Possible causes:**
- Proxy is not fully initialized yet
- LiteLLM JSON response is malformed
- Network connectivity issue

**Solution:**

1. Wait for proxy to be fully ready:
   ```bash
   sleep 3
   ```

2. Try again:
   ```bash
   bin/litellm-proxy guardrails on
   ```

3. Check proxy logs for errors:
   ```bash
   docker logs litellm-proxy 2>&1 | tail -20
   ```

4. If still failing, restart the proxy:
   ```bash
   bin/litellm-proxy stop
   sleep 2
   bin/litellm-proxy start
   sleep 3
   bin/litellm-proxy guardrails on
   ```

### Problem: Guardrails Command Not Found

**Diagnosis:**
```bash
bin/litellm-proxy guardrails on
# Error: guardrails: unknown command
```

**Solution:**

1. Update the script to latest version:
   ```bash
   git pull origin main
   ```

2. Verify the guardrails function exists:
   ```bash
   grep -c "cmd_guardrails" bin/litellm-proxy
   # Should output: 1 (or more)
   ```

3. Test with explicit help:
   ```bash
   bin/litellm-proxy help
   ```

---

## Related Documentation

- **Quick Reference**: `GUARDRAILS-QUICK-REFERENCE.md` — cheat sheet for common commands
- **Implementation Details**: `GUARDRAILS-IMPLEMENTATION.md` — internal architecture and API usage
- **LiteLLM Guardrails Docs**: https://docs.litellm.ai/docs/proxy/guardrails
- **Presidio PII Detection**: https://microsoft.github.io/presidio/
- **LiteLLM Admin API**: https://docs.litellm.ai/docs/proxy/admin_ui

---

**Last updated**: 2026-08-29  
**Guardrails implementation version**: v1.0
