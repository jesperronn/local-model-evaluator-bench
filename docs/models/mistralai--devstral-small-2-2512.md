# mistralai/devstral-small-2-2512

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `mistralai/devstral-small-2-2512` |
| **Alias** | `devstral2-small` |
| **Family / arch** | Devstral 2 (Mistral), dense |
| **Parameter count** | 24B |
| **Context window** | 256K |
| **License** | Apache-2.0 |
| **Disk size** | 15.2 GB (GGUF, lmstudio-community Q4) |
| **Added** | 2026-06-25 |
| **Last run** | 2026-06-29 (run `20260629-061049`) |
| **Doc updated** | 2026-06-30 |
| **Removed** | 2026-06-29 — dropped from `models.txt` after poor bench results |

## Results summary

Disappointing across most adapters. aider is the standout at 94%, but opencode and openhands collapse to 37% — same baseline as LMS-incompatible caveman/copilot, indicating stall or error rather than partial capability. interpreter underperforms (78%) relative to other models where it hits 97–100%. Overall 249/356 (69%); excluding caveman/copilot: ~225/260 ≈ 86%, but opencode/openhands failures are real capability misses, not LMS compat issues.

| Adapter | 2026-06-29 (LMS) | Notes |
|---------|-----------------|-------|
| aider | 36/38 (94%) | Best adapter for this model |
| goose | 34/38 (89%) | |
| hermes | 34/38 (89%) | |
| pi | 34/38 (89%) | |
| cline | 33/38 (86%) | |
| interpreter | 30/38 (78%) | Below expected baseline |
| opencode | 12/32 (37%) | Stalls/errors — not LMS compat, model-specific |
| openhands | 12/32 (37%) | Stalls/errors |
| caveman | 12/32 (37%) | LMS incompatible |
| copilot | 12/32 (37%) | LMS incompatible |
| nanocoder | 33/38 (87%) | bash-01 1/4 (execute_bash blocked); smoke-01 0/2; all JS cases PASS |
| codex | SKIPPED | in compat.json |

## Failure patterns

**opencode/openhands collapse:** Both adapters score 37% — the same baseline achieved by LMS-incompatible caveman/copilot. For devstral this is not a protocol mismatch but a model behavior issue: the model either stalls mid-task or produces output these adapters cannot complete the task with. aider, goose, and hermes handle the same cases fine, ruling out task difficulty.

**interpreter underperformance:** 78% vs 97–100% on comparable models (qwen3.5-9b, gemma-4-26b-a4b-qat). Dense 24B with 256K context may be overkill for interpreter's simpler tool call style — or the model doesn't follow interpreter's tool protocol as well as qwen/gemma models.

**aider near-perfect:** 36/38 (94%) — 2 cases fail. Best adapter for this model. Aider's whole-file edit format likely suits Devstral's training on multi-file agentic tasks.

## Status

**Removed 2026-06-29** — dropped from `models.txt` after a full benchmark sweep. The model underperforms its SWE-Bench 68% marketing claim in this benchmark environment. opencode and openhands failures are concerning for a model marketed as an agentic coding specialist.

Better alternatives:
- For agentic coding: `qwen/qwen3.6-35b-a3b` (100% across all working adapters)
- For 24B-class dense: `qwen/qwen3.6-27b` (93% on LMS GGUF)

## Download

```bash
lms get mistralai/devstral-small-2-2512
lms ls --json | jq -r '.[].modelKey' | grep -i devstral
```

GGUF is published by the LM Studio community team (`lmstudio-community/Devstral-Small-2-24B-Instruct-2512-GGUF`).
