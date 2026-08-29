# Guardrails Runtime Control Implementation

## Summary

Enhanced `bin/litellm-proxy` with guardrails runtime control, allowing dynamic enable/disable of Presidio PII detection without proxy restart.

## Changes Made

### 1. Enhanced `bin/litellm-proxy` script

#### New Helper Function: `_get_guardrails_status()`
- Fetches guardrails state from LiteLLM Admin API `/admin/config` endpoint
- Extracts enabled guardrail name and entity list
- Returns formatted status string: `"on (presidio, PERSON|EMAIL_ADDRESS|...)"` or `"off"`
- Handles authentication via `$LITELLM_MASTER_KEY` if set

#### Updated Function: `cmd_status()`
- Now includes guardrails state in output
- Displays line: `guardrails: on|off (with entity details when on)`
- Format matches requirement: `"guardrails: on (presidio, PERSON|EMAIL_ADDRESS|...)"`

#### New Function: `cmd_guardrails()`
Implements four subcommands:

**1. `guardrails on`**
- Fetches current config via GET `/admin/config`
- Updates `default_on: true` for `presidio-pii` guardrail
- POSTs updated config back to proxy
- No proxy restart required
- Output: `"guardrails: enabled (presidio-pii)"`

**2. `guardrails off`**
- Fetches current config via GET `/admin/config`
- Updates `default_on: false` for `presidio-pii` guardrail
- POSTs updated config back to proxy
- No proxy restart required
- Output: `"guardrails: disabled"`

**3. `guardrails status`**
- Shows current guardrails state
- Output: `"guardrails: off"` or `"guardrails: on (presidio, PERSON|EMAIL_ADDRESS|PHONE_NUMBER|CREDIT_CARD)"`

**4. `guardrails config`**
- Displays full guardrails configuration as JSON
- Shows all entities, thresholds, mask operator, etc.

#### Updated Case Statement
- Routing: `guardrails)  cmd_guardrails "${2:-status}";;`
- Defaults to `status` subcommand if none specified

### 2. Updated Usage Documentation

Updated script header comments to include:
```
bin/litellm-proxy guardrails on      enable guardrails (presidio PII detection)
bin/litellm-proxy guardrails off     disable guardrails
bin/litellm-proxy guardrails status  show current guardrails state
bin/litellm-proxy guardrails config  show full guardrails configuration
```

And updated status command description:
```
bin/litellm-proxy status  is it up, DB connected, per-route model counts, guardrails state
```

### 3. API Integration

All commands use LiteLLM Admin API endpoints:

- **GET `/admin/config`** — Fetch current configuration (read-only)
- **POST `/admin/config`** — Update configuration at runtime

Key implementation details:
- Uses `jq` for JSON parsing and manipulation
- Automatically handles `$LITELLM_MASTER_KEY` authorization if set
- 3-second timeout on all API calls
- Proper error handling with informative messages

### 4. Configuration

The guardrails configuration in `config-templates/litellm.yaml`:

```yaml
guardrails:
  - guardrail_name: "presidio-pii"
    guardrail: "presidio"
    mode: "pre_call"
    default_on: false              # Changed at runtime via on/off commands
    entities:
      - "PERSON"
      - "EMAIL_ADDRESS"
      - "PHONE_NUMBER"
      - "CREDIT_CARD"
    score_thresholds: { ... }
    deny_list: []
    mask_operator: "MASK"
```

## Testing & Verification

### Inline Validation Tests
File: `test-guardrails-inline.sh`

Validates script structure without requiring running proxy:
- ✓ Function definitions present
- ✓ All four subcommands implemented
- ✓ Status command includes guardrails check
- ✓ Guardrails state extraction logic present
- ✓ Error handling for proxy down
- ✓ `/admin/config` endpoint usage
- ✓ POST updates to config
- ✓ Output format correctness

Run:
```bash
./test-guardrails-inline.sh
```

### Integration Tests
File: `test-guardrails.sh`

Comprehensive tests with running proxy (8 tests):
1. Guardrails status command works
2. Guardrails config returns valid JSON
3. Guardrails on command succeeds
4. Proxy running after `guardrails on`
5. Guardrails status shows "on"
6. Guardrails off command succeeds
7. Guardrails status shows "off"
8. Proxy responsive after all commands

Run:
```bash
bin/litellm-proxy start
./test-guardrails.sh
```

## Verification Checklist

### Command Functionality
- [x] `bin/litellm-proxy guardrails on` — enables guardrails via API
- [x] `bin/litellm-proxy guardrails off` — disables guardrails via API
- [x] `bin/litellm-proxy guardrails status` — shows on/off state
- [x] `bin/litellm-proxy guardrails config` — shows JSON config
- [x] All commands work without proxy restart

### Status Output
- [x] `bin/litellm-proxy status` includes guardrails line
- [x] Format: `"guardrails: on (presidio, PERSON|EMAIL_ADDRESS|...)"`
- [x] Format when off: `"guardrails: off"`

### API Integration
- [x] Uses LiteLLM Admin API `/admin/config` endpoint
- [x] GET for fetching config
- [x] POST for updating config
- [x] Handles `$LITELLM_MASTER_KEY` authentication
- [x] Proper error messages when proxy not running

### No Restart Required
- [x] Status updates immediately after on/off
- [x] Proxy continues running during commands
- [x] All endpoints remain responsive

## Usage Examples

### Enable guardrails for a test run
```bash
bin/litellm-proxy start
bin/litellm-proxy guardrails on
# Run tests with PII masking enabled
bin/litellm-proxy status  # Shows: guardrails: on (presidio, ...)
bin/litellm-proxy guardrails off
```

### Check guardrails state before making requests
```bash
if bin/litellm-proxy guardrails status | grep -q "on"; then
  echo "PII will be masked in prompts"
fi
```

### View full configuration
```bash
bin/litellm-proxy guardrails config | jq '.[] | {name: .guardrail_name, entities: .entities}'
```

### Automated control in scripts
```bash
#!/bin/bash
bin/litellm-proxy guardrails on
pytest tests/security/
bin/litellm-proxy guardrails off
pytest tests/performance/
```

## Files Modified

- `/Users/jesper/src/local-model-evaluator-bench/bin/litellm-proxy` — main script

## Files Created

- `/Users/jesper/src/local-model-evaluator-bench/docs/GUARDRAILS.md` — user documentation
- `/Users/jesper/src/local-model-evaluator-bench/test-guardrails.sh` — integration tests
- `/Users/jesper/src/local-model-evaluator-bench/test-guardrails-inline.sh` — inline validation
- `/Users/jesper/src/local-model-evaluator-bench/GUARDRAILS-IMPLEMENTATION.md` — this file

## Implementation Details

### Architecture
```
bin/litellm-proxy guardrails [on|off|status|config]
                         |
                         v
                  cmd_guardrails()
                         |
              +----------+----------+----------+
              |          |          |          |
              v          v          v          v
           "on"       "off"      "status"   "config"
             |          |          |          |
             +-------+--+          |          |
                     |             |          |
         GET /admin/config (fetch current)    |
             |                    |          |
         jq update (set default_on=true/false)|
             |                    |          |
         POST /admin/config       |          |
                                  v          v
                       _get_guardrails_status() GET /admin/config
                                  |          |
                                  +--output--+
```

### Error Handling
All commands include error handling for:
- Proxy not running: "check proxy is running (bin/litellm-proxy status)"
- Invalid subcommands: "unknown guardrails command: ... (use: on | off | status | config)"
- JSON parse failures: Graceful fallback with informative message

### Authentication
If `$LITELLM_MASTER_KEY` is set, all API calls include:
```bash
-H "Authorization: Bearer $LITELLM_MASTER_KEY"
```

This matches LiteLLM's admin API authentication scheme.

## Dependencies

- `curl` — HTTP requests to LiteLLM Admin API
- `jq` — JSON parsing and manipulation
- `docker` — to run the LiteLLM proxy container
- `bash` — script language

All are already available in the project environment.

## Performance Considerations

- API calls have 3-second timeout (won't block indefinitely)
- No caching — always fetches latest config for accuracy
- Minimal overhead: single API call per command
- No proxy restart needed: changes apply immediately

## Future Enhancements

Possible improvements:
1. Support multiple guardrails (currently only presidio-pii)
2. Per-entity enable/disable (e.g., `guardrails mask PERSON`)
3. Threshold adjustment at runtime
4. Guardrails statistics/metrics display
5. Logging of guardrails actions

## References

- LiteLLM Admin API: https://docs.litellm.ai/docs/proxy/admin_ui
- LiteLLM Guardrails: https://docs.litellm.ai/docs/proxy/guardrails
- Presidio PII Detection: https://microsoft.github.io/presidio/
