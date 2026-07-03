# Qwen2.5-Coder 7B — Testing & Tracking Narrative

**Status**: 🟠 Nightly in progress, expansion queued  
**Start**: 2026-07-02 22:00 CEST  
**Model**: qwen/qwen2.5-coder-7b (7B, LM Studio + Ollama)

---

## Tracking Strategy

You're monitoring three use cases across all test phases:

### 1. **Regression Detection** — Did we get worse?
```bash
bin/bench-status --compare 20260702-224527
```
- Compare latest run against a known-good baseline
- Identifies: adapter failures, performance drops, new incompatibilities
- Used after: each expansion phase to catch issues early

### 2. **Trend Analysis** — How are we doing over time?
```bash
bin/bench-status --history 10
```
- Track pass rates across runs to spot patterns
- Identifies: improving adapters, consistent failures, model stability
- Used: weekly/nightly to catch drift in test harness or model behavior

### 3. **Investigation** — What happened in that run?
```bash
bin/bench-status --run 20260702-224527
```
- Deep dive into specific run results
- Identifies: which adapters + cases failed, latency patterns, edge cases
- Used: when anomaly detected, to understand root cause

---

## Test Phases & Timeline

### Phase 0: Smoke Tests ✅ COMPLETE
**Runs**: `20260702-224527` (LM Studio)  
**Result**: 3 adapters 100% PASS (aider, cline, interpreter)  
**Verdict**: ✅ Model can reach and work with adapters

**Key finding**: Aider excels on smoke tests (23s total for 3 cases)

---

### Phase 1: Nightly Benchmark 🟠 IN PROGRESS
**Run**: `20260702-230930`  
**Command**: `bin/nightly --model qwen2.5-coder-7b`  
**Scope**: 7 adapters × 7 cases × easy+medium difficulty  
**Status**: ~49/49 cases complete, last adapters finishing

**Preliminary results** (still running):
- **aider**: 6/7 PASS (85%) — solid performance
- **cline**: 3/7 PASS (42%) — struggles with bash, TypeScript
- **codex**: 3/7 PASS (42%) — similar issues as cline
- **copilot/goose/pi/opencode**: Mixed, still running

**Early verdict**: Aider is the clear winner. Cline/codex have timeout issues on complex cases (TypeScript groupby hitting 300s+ stalls).

---

### Phase 2: Hard Difficulty (Queued) ⏳ PENDING
**Trigger**: Once nightly completes  
**Command**:
```bash
bin/bench \
  --agent aider,cline,codex \
  --model qwen2.5-coder-7b \
  --difficulty hard \
  --runtime lms
```
**Purpose**: Find model's ceiling on complex tasks  
**Expected**: ~60-70% pass rate (normal for 7B)  
**Track with**: `bin/bench-status --history 5` to spot hard-case failures

---

### Phase 3: Ollama Validation (Queued) ⏳ PENDING
**Trigger**: After phase 2  
**Command**:
```bash
bin/bench \
  --agent opencode-proxy \
  --model qwen2.5-coder-7b \
  --difficulty easy,medium \
  --runtime ollama
```
**Purpose**: Verify cross-runtime parity (Ollama vs LM Studio)  
**Track with**: `bin/bench-status --compare 20260702-230930` to spot Ollama-specific regressions

---

## Gaps We're Hunting

### Functional Gaps (Blocking Issues)
- [ ] Why do cline/codex timeout on TypeScript cases?
- [ ] Does hard difficulty break any adapter entirely?
- [ ] Ollama performance — does proxy overhead matter?

### Performance Gaps (Quality Issues)  
- [ ] Aider at 85% — what are the 15% failures?
- [ ] Bash task performance — generic weakness or adapter-specific?
- [ ] Context window — can model use full 64K effectively?

### Integration Gaps (Usability Issues)
- [ ] Which adapters are production-ready (>80%)?
- [ ] Which cases are model-specific vs adapter-specific failures?
- [ ] How does this compare to qwen3.6-35b baseline?

---

## Monitoring Checklist

### After Each Phase
```bash
# 1. Check current results
bin/bench-status

# 2. Compare vs baseline
bin/bench-status --compare 20260702-230930

# 3. Spot trends
bin/bench-status --history 5

# 4. If regression found
bin/bench-status --run <run-id>  # Investigate
```

### Key Metrics to Watch
- **Overall pass rate** by phase (should stay ≥70%)
- **Aider performance** (baseline for model quality)
- **Adapter spread** (which hit 80%+ = production-ready)
- **Latency trends** (longer = model struggling?)

---

## Decision Thresholds

| Phase | Metric | Go | Caution | Stop |
|-------|--------|-----|---------|------|
| Nightly | Overall % | >75% | 70-75% | <70% |
| Hard | Aider % | >70% | 60-70% | <60% |
| Ollama | vs LM Studio | ±5% | ±10% | >10% |

---

## Next Checkpoint

**Nightly completes in**: ~10-30 min  
**Then**: Auto-trigger phase 2 (hard cases, 45 min)  
**Then**: Auto-trigger phase 3 (Ollama, 30 min)  
**Total ETA**: ~2 hours until all expansion phases complete

**You can**:
- `tail -f /tmp/expand-watch.log` — monitor auto-expansion
- `bin/bench-status` — check latest results anytime
- `bin/bench-status --history 10` — track trends as phases complete

---

## Key Artifacts

- **Latest run**: Check with `bin/bench-status`
- **All runs**: `results/` directory (timestamped folders)
- **Trend data**: `results/*/results.csv` (one per run)
- **Compatibility**: `compat.json` (auto-updated by bin/bench)
- **This narrative**: Keeps growing as phases complete

---

**Last updated**: 2026-07-03 00:15 CEST  
**Document**: Living record — refresh with new phase results
