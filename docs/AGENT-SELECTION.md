# Agent Selection Guide

This benchmark includes 11 agents. **All are available for testing**, but performance varies widely. This guide helps you choose wisely.

## Quick Recommendation Matrix

|  | **Speed** | **Accuracy** | **Reliability** | **Use When** |
|---|-----------|-------------|-----------------|--------------|
| 🏆 **openhands** | 55s/case | 100% | Excellent | Balanced production use; want both speed & accuracy |
| 🏆 **cline** | 68s/case | 100% | Excellent | Need perfect accuracy; time is secondary |
| 🏆 **aider** | 96s/case | 97% | Excellent | Proven workhorse; established track record |
| ⚠️ **goose** | 79s/case | 100% | Good | Need 100% but can wait; self-verify cases |
| ⚠️ **pi** | 151s/case | 87% | Fair | Exploring; know tool-call formats work |
| ⚠️ **opencode** | 543s/case | 71% | Fair | Exploratory; benchmarking only |
| ❌ **codex** | 363s/case | 76% | Poor | Avoid; too slow, not accurate enough |
| ❌ **copilot** | 453s/case | 63% | Poor | Avoid; very slow, low accuracy |
| ⚠️ **caveman** | 77s/case | 60% | Poor | Text-based fallback; weak results; LMS adapter unsupported |
| ❌ **hermes** | 87s/case | 59% | Poor | Needs special config; lower accuracy |
| ❌ **interpreter** | 71s/case | 98% | Experimental | Research only; high overhead |

## Baseline Results (qwen/qwen3.6-35b-a3b + LM Studio)

```
Pass rate by agent:
  openhands    21/21 (100%)  ✨
  cline        21/21 (100%)  ✨
  goose        21/21 (100%)  ✨
  aider        20/21 (97.4%) ✨
  pi           16/21 (76%)
  opencode     12/21 (57%)
  codex        12/21 (57%)
  copilot       7/21 (33%)
  caveman      0/7 baseline (60% overall)
  hermes       0/7 baseline (59% overall)
```

## Use Cases

### Production / CI Systems
**Pick: openhands or aider**
- openhands: Fastest perfect-score agent (55s/case)
- aider: Proven reliability, 97% accuracy, mature codebase
- ✅ Run both; pick fastest for your use case

### Accuracy-Critical Tasks
**Pick: openhands, cline, or goose**
- All achieve 100% on baseline
- openhands is fastest (55s/case)
- cline is solid middle ground (68s/case)
- goose if time is not a constraint (79s/case)

### Research / Exploration
**Run any; collect data**
- All agents available to gather data
- Slow/weak agents still provide insights
- Just expect lower accuracy and longer runtimes
- Reference this guide when interpreting results

### Speed-Critical (< 60s/case)
**Pick: openhands only**
- openhands: 55s/case (baseline)
- No other agent beats this for perfect accuracy

## Common Mistakes

❌ **Don't:** Run codex or copilot expecting competitive results (very slow, weak)
✅ **Do:** Run openhands first; fast + accurate baseline

❌ **Don't:** Use caveman-lms without checking adapter status; it requires npm caveman-code custom-provider support
✅ **Do:** Use caveman with ollama/mlx runtimes, or read docs/tools/caveman.md for details

❌ **Don't:** Use hermes without understanding its limitations
✅ **Do:** Read docs/tools/hermes.md first

❌ **Don't:** Blame an agent's output quality before checking its recommendation tier
✅ **Do:** Consult this guide; some agents are for exploration, not production

## Viewing Current Performance

Show all agents sorted by speed:
```bash
bin/report --all --speed
```

Filter to recommended agents only:
```bash
bin/report --all --model qwen/qwen3.6-35b-a3b --tool openhands,cline,aider
```

Show by accuracy (default leaderboard):
```bash
bin/report --all
```

## Why Keep Weak Agents?

This benchmark values **data completeness**. Even agents with lower accuracy provide:
- Comparative insights (why is X slower than Y?)
- Research data (which agents fail on which cases?)
- Edge case coverage (do slow agents succeed where fast ones fail?)

But we guide users toward effective choices with this matrix.

---

**Last updated:** 2026-06-27 (baseline: qwen3.6-35b-a3b + LM Studio)
**See also:** docs/tools/*.md for per-agent deep dives
