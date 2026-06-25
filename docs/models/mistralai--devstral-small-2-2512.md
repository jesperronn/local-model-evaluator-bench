# mistralai/devstral-small-2-2512

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `mistralai/devstral-small-2-2512` (confirm via `lms ls --json` after download) |
| **Alias** | `devstral2-small` |
| **Family / arch** | Devstral 2 (Mistral), dense |
| **Parameter count** | 24B |
| **Context window** | 256K |
| **License** | Apache-2.0 |
| **Disk size** | <!-- TODO after download --> |
| **Added** | 2026-06-25 |
| **Last run** | — (not yet run) |
| **Doc updated** | 2026-06-25 |
| **Workarounds needed** | <!-- TODO — determine on first run --> |

## Download

```bash
lms get mistralai/devstral-small-2-2512
# confirm the exact modelKey, then update models.txt / models-aliases.conf if it differs:
lms ls --json | jq -r '.[].modelKey' | grep -i devstral
```

GGUF is published by the LM Studio community team
(`lmstudio-community/Devstral-Small-2-24B-Instruct-2512-GGUF`). Fits a 32GB Mac.

## Smoke test

```bash
bin/smoke --runtime lms --model devstral2-small
```

Runs `smoke-00-hello`, `smoke-01-edit-file`, `smoke-02-numbers` across all
installed adapters. PASS = adapter reached the model and completed the task.

## Results summary

Not yet benchmarked. Reference scores from Mistral: SWE-Bench Verified 68.0%,
SWE-Bench Multilingual 55.7%. Agentic-coding specialist built for tool use
(multi-file edits, codebase exploration) with vision support.

## Status

**under-evaluation** — wired into lms model list + aliases; awaiting download and
first smoke run. mlx / ollama variants not pulled yet (alias maps them to `-`).
