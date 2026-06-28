# zai-org/glm-4.7-flash

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `zai-org/glm-4.7-flash` (confirm via `lms ls --json` after download) |
| **Family / arch** | GLM-4.7 (Zhipu AI), dense transformer |
| **Parameter count** | 30B |
| **Context window** | 128K tokens |
| **License** | <!-- TODO — verify from HuggingFace card --> |
| **Disk size** | 24.36 GB (GGUF, lmstudio-community) |
| **Added** | 2026-06-28 |
| **Last run** | — (not yet run) |
| **Doc updated** | 2026-06-28 |
| **Workarounds needed** | <!-- TODO — determine on first run --> |

## Download

```bash
lms get zai-org/glm-4.7-flash
# confirm the exact modelKey:
lms ls --json | jq -r '.[].modelKey' | grep -i glm
```

GGUF is published by the LM Studio community team. Fits a 32GB Mac.

## Smoke test

Run once to validate adapter wiring:
```bash
bin/smoke --runtime lms --model zai-org/glm-4.7-flash
```

Expected: PASS on all adapters.

## Performance notes

<!-- Populated after first full run -->

## Observations across runs

- 2026-06-28 (initial): smoke test passed; model performs [pending full bench run]
