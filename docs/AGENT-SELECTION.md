# Agent Selection Guide

This benchmark includes 12 agents. **All are available for testing**, but performance varies widely. This guide helps you choose wisely.

## Quick Recommendation Matrix

Based on 2026-06-29 overnight sweep across 7 models on LMS runtime.

|  | **Speed** | **Accuracy** | **Use When** |
|---|-----------|-------------|--------------|
| 🏆 **aider** | 11–96s/case | 94–100% | Production use; fastest on MoE models; very reliable |
| 🏆 **interpreter** | 23–160s/case | 97–100% | When aider isn't available; clean tool-use protocol |
| 🏆 **cline** | 20–300s/case | 82–100% | When you need maximum accuracy on complex tasks |
| ✅ **hermes** | 14–140s/case | 89–100% | Good all-rounder; needs special config |
| ✅ **goose** | 57–110s/case | 89–100% | Reliable; good on self-verify cases |
| ✅ **pi** | 12–300s/case | 89–97% | Generally reliable; use if others aren't available |
| ✅ **opencode** | 8–300s/case | 37–97% | Generally reliable but model-dependent |
| ✅ **openhands** | 28–254s/case | 37–92% | Good on most models; collapses on devstral |
| ⚠️ **nanocoder** | TBD | TBD | New — smoke-testing in progress (2026-06-30) |
| ❌ **codex** | 12–301s/case | 65–100% | ts-01 error(1) on some models; mixed reliability |
| ❌ **caveman** | 2s (error) | 37% | LMS incompatible — works on Ollama only |
| ❌ **copilot** | variable | 37–56% | LMS incompatible — patch format issues |

## Per-Model Results (2026-06-29 overnight, LMS)

| Model | Best adapters | Avoid |
|-------|--------------|-------|
| qwen3.6-35b-a3b | all working = 100% | caveman, copilot (LMS compat) |
| qwen3.5-9b | aider 100%, interpreter 100% | caveman, copilot (LMS compat) |
| devstral-small-2-2512 | aider 94%, goose/hermes/pi 89% | opencode, openhands (37%), codex (skipped) |
| gemma-4-26b-a4b-qat | goose/hermes/pi 100%, opencode/interpreter 97% | caveman (LMS), codex (compat.json) |
| qwen3.6-27b | codex/goose/interpreter 100%, hermes 97% | 5 adapters not run |
| glm-4.7-flash | codex 65% (only viable) | everything else (timeout floor at 37%) |
| qwen3-coder-30b | aider 100% avg 11s, interpreter 100% | caveman (LMS), cline/opencode not yet run |

## Use Cases

### Production / Agentic Coding
**Pick: aider or interpreter**
- aider: fastest per-case (11s on MoE models), 100% on best models
- interpreter: clean tool-call protocol, 100% on multiple models
- Both are reliable across all model families tested

### Accuracy-Critical Tasks
**Pick: cline, hermes, or goose**
- cline: 100% on qwen3.6-35b-a3b and qwen3.5-9b; slower on complex cases
- hermes: 100% on gemma-4-26b-a4b-qat and qwen3.6-35b-a3b; needs `backend: local` config
- goose: 100% on gemma/qwen3.6-27b; reliable but slower

### Speed-Critical (< 30s/case)
**Pick: aider only**
- aider with qwen3-coder-30b: avg 11s
- aider with qwen3.6-35b-a3b: avg ~40s

### Research / Exploration
**Run nanocoder, codex, opencode** — gather data, expect variable accuracy

## Adapter Setup Notes

| Adapter | Setup required | Notes |
|---------|---------------|-------|
| aider | `pip install aider-chat` | Works out of box |
| interpreter | `pip install open-interpreter` | `NANOCODER_TRUST_DIRECTORY=1` not needed |
| cline | `pnpm install -g cline` | Falls back to pnpm store if PATH broken |
| hermes | hermes config.yaml: `backend: local`, `approvals.mode: smart` | `bin/doctor` verifies |
| goose | `pipx install goose-ai` | Works out of box |
| pi | `pip install pipecat` | Tool-call shim enabled for nested edits |
| opencode | `npm install -g opencode` | Glob issue on gemma-4-e4b |
| openhands | Docker or pip | Collapses on devstral (model issue) |
| nanocoder | `npm install -g nanocoder` | v1.28.1; LMS provider via env var |
| codex | `npm install -g @openai/codex` | wire_api=chat incompatibility on some configs |
| caveman | n/a on LMS | Use Ollama runtime only |
| copilot | n/a on LMS | Patch format incompatible with most models |

## Why Keep Weak Agents?

This benchmark values **data completeness**. Even agents with lower accuracy provide:
- Comparative insights (why is X slower than Y?)
- Research data (which agents fail on which cases?)
- Model-specific failure patterns (e.g., opencode collapses on devstral but is 97% on gemma)

---

**Last updated:** 2026-06-30 (2026-06-29 overnight sweep: 7 models × 11 adapters on LMS)
**See also:** docs/tools/*.md for per-agent deep dives, docs/models/*.md for per-model results
