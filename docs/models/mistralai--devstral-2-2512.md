# mistralai/devstrint-2-2512

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | measured pending |
| **Speed (avg)** | measured pending |
| **Best adapter** | measured pending |
| **Recommended for** | measured pending |
| **Status** | watch |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `mistralai/devstral-2-2512` (confirm via `lms ls --json` after download) |
| **Alias** | `devstral2` |
| **Family / arch** | Devstral 2 (Mistral), dense |
| **Parameter count** | 123B |
| **Context window** | 256K |
| **License** | Apache-2.0 |
| **Disk size** | measured pending |
| **Added** | 2026-06-25 |
| **Last run** | — (not yet run) |
| **Doc updated** | 2026-06-25 |
| **Workarounds needed** | measured pending |

## Results summary

Not yet benchmarked. Reference scores from Mistral: SWE-Bench Verified 72.2%, SWE-Bench Multilingual 61.3%. Agentic-coding model with tool use and vision.

## Timing observations
measured pending

## Failure patterns
none

## Better alternatives
measured pending

## Status

**under-evaluation** — wired into lms model list + aliases; awaiting download and first smoke run. Gated on fitting in RAM. mlx / ollama variants not pulled yet.

## Additional Information

### ⚠️ RAM warning

123B dense — likely exceeds available RAM on this machine. **Unload every other
model first** and run it alone. May not fit at all; if `lms load` fails or the
machine swaps hard, drop to `devstral2-small` (24B). Test this one last.

### Download & Smoke test

```bash
# download
lms get mistralai/devstral-2-2512
lms ls --json | jq -r '.[].modelKey' | grep -i devstral

# unload everything else first
lms unload --all
bin/smoke --runtime lms --model devstral2
```
