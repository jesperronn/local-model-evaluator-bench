# Agent Selection Guide

This benchmark includes 12 agents. **All are available for testing**, but performance varies widely. This guide helps you choose wisely.

## Quick Recommendation Matrix

LMS sweep: 7 models × 12 adapters.

|  | **Speed** | **Accuracy** | **Use When** |
|---|-----------|-------------|--------------|
| 🏆 **aider** | 11–96s/case | 94–100% | Production; fastest on MoE models |
| 🏆 **interpreter** | 23–160s/case | 97–100% | Fallback to aider; clean tool-use protocol |
| 🏆 **cline** | 20–300s/case | 82–100% | Maximum accuracy on complex tasks |
| ✅ **hermes** | 14–140s/case | 89–100% | Good all-rounder; needs `backend: local` config |
| ✅ **goose** | 57–110s/case | 89–100% | Reliable on self-verify cases |
| ✅ **pi** | 12–300s/case | 89–97% | Fallback; generally reliable |
| ✅ **opencode** | 8–300s/case | 37–97% | Reliable but model-dependent |
| ✅ **openhands** | 28–254s/case | 37–92% | Most models; collapses on devstral |
| ✅ **nanocoder** | 8–250s/case | 35–97% | Bash blocked (execute_bash), XML issue on 9b (71%), GLM too slow |
| ❌ **codex** | 12–301s/case | 65–100% | ts-01 error(1) on some models; mixed reliability |
| ✅ **caveman** | speed measured pending | 87.1% (pre-break data) | Fixed 2026-07-07 on both LMS and Ollama — see docs/tools/caveman.md |
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
| qwen3-coder-30b | aider/interpreter/goose 100%, pi 97%, codex/hermes/openhands 92% | caveman (LMS), cline/opencode not yet run |

## Use Cases

| Goal | Pick |
|------|------|
| Production coding | aider or interpreter |
| Accuracy-critical | cline, hermes, or goose |
| Speed-critical (< 30s) | aider only |
| Research / data gathering | nanocoder, codex, opencode (expect variable accuracy) |

## Adapter Setup Notes

| Adapter | Setup required | Notes |
|---------|---------------|-------|
| aider | `pip install aider-chat` | Works out of box |
| interpreter | `pip install open-interpreter` | `NANOCODER_TRUST_DIRECTORY=1` not needed |
| cline | `pnpm install -g cline` | Falls back to pnpm store if PATH broken |
| hermes | hermes config.yaml: `backend: local`, `approvals.mode: smart` | `bin/doctor` verifies |
| goose | `pipx install goose-ai` | Works out of box |
| pi | `npm install -g @earendil-works/pi-coding-agent` | Tool-call shim enabled for nested edits |
| opencode | `npm install -g opencode` | Glob issue on gemma-4-e4b |
| openhands | Docker or pip | Collapses on devstral (model issue) |
| nanocoder | `npm install -g nanocoder` | v1.28.1; LMS provider via env var |
| codex | `npm install -g @openai/codex` | wire_api=chat incompatibility on some configs |
| caveman | `npm install -g @juliusbrussee/caveman-code` | Works on LMS and Ollama (fixed 2026-07-07, see docs/tools/caveman.md) |
| copilot | n/a on LMS | Patch format incompatible with most models |

## Why Keep Weak Agents?

This benchmark values **data completeness**. Even agents with lower accuracy provide:
- Comparative insights (why is X slower than Y?)
- Research data (which agents fail on which cases?)
- Model-specific failure patterns (e.g., opencode collapses on devstral but is 97% on gemma)

---

**Last updated:** 2026-06-30 (overnight sweep: 7 models × 12 adapters on LMS; nanocoder full sweep complete)
**See also:** docs/tools/*.md for per-agent deep dives, docs/models/*.md for per-model results
