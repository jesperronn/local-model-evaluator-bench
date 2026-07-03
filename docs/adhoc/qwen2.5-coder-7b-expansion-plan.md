# Qwen2.5-Coder 7B — Expansion Testing Plan

**Trigger**: Execute once `bin/nightly` passes with >70% average

## Phase 1: Hard Difficulty Cases (LM Studio)

Test the model on harder problem sets to assess upper performance ceiling.

```bash
bin/bench \
  --agent aider,cline,codex,opencode \
  --model qwen2.5-coder-7b \
  --difficulty hard \
  --runtime lms \
  --timeout 300 \
  --warmup 180 \
  --stall 120
```

**Purpose**: Identify where model struggles on complex tasks  
**Expected**: Likely 40-60% on hard cases (typical for 7B models)  
**Duration**: 30-45 min (only top 4 adapters)

---

## Phase 2: Ollama with Proxy Adapters

Test on Ollama using tool-call-proxy for adapters that require JSON conversion.

```bash
# Start proxy if not running
pgrep tool-call-proxy || bin/tool-call-proxy &
sleep 2

# Test proxy variants
bin/bench \
  --agent opencode-proxy,copilot \
  --model qwen2.5-coder-7b \
  --runtime ollama \
  --difficulty easy,medium \
  --timeout 300 \
  --warmup 180 \
  --stall 120
```

**Purpose**: Validate Ollama backend + proxy stack  
**Expected**: Similar performance to LM Studio (slight variance due to backend)  
**Duration**: 20-30 min

---

## Phase 3: Extended Adapter Coverage (LM Studio)

Test adapters not in nightly run (hermes, interpreter, openhands, pi, goose).

```bash
bin/bench \
  --agent hermes,interpreter,openhands,pi,goose \
  --model qwen2.5-coder-7b \
  --difficulty easy,medium \
  --runtime lms \
  --timeout 300 \
  --warmup 180 \
  --stall 120
```

**Purpose**: Assess performance across full adapter suite  
**Expected**: Mixed results (some adapters historically struggle with certain models)  
**Duration**: 40-60 min

---

## Phase 4: Edge Cases & Stress Testing

Test boundary conditions to identify failure modes.

**4a) Long Context Window Test**
```bash
# Test with near-max context (qwen2.5 supports 131K)
bin/bench \
  --agent aider \
  --model qwen2.5-coder-7b \
  --difficulty easy \
  --runtime lms \
  --timeout 300 \
  --warmup 180 \
  --stall 120 \
  --custom-context 100000
```

**4b) Rapid Sequential Calls (Cache Stress)**
```bash
# Multiple rapid invocations of same task
for i in {1..5}; do
  echo "Rapid test iteration $i..."
  bin/smoke --runtime lms --model qwen2.5-coder-7b --agent aider --cases smoke-00-hello
done
```

**Purpose**: Identify memory leaks, cache issues, context window limitations  
**Duration**: 20-30 min

---

## Phase 5: Comparative Analysis

Compare qwen2.5-coder-7b against baseline models on the same cases.

```bash
# Compare against qwen3.6-35b-a3b (reference model)
bin/bench \
  --agent aider,cline \
  --model qwen2.5-coder-7b,qwen3.6-35b-a3b \
  --difficulty easy,medium \
  --runtime lms \
  --timeout 300 \
  --warmup 180 \
  --stall 120
```

**Purpose**: Establish performance relative to known baseline  
**Expected**: qwen2.5-7b ~80-90% of qwen3.6-35b performance (7B vs 35B comparison)  
**Duration**: 60-90 min

---

## Gap Analysis Checklist

Once expansion tests complete, evaluate:

### Functional Gaps
- [ ] Which adapters fail to reach model?
- [ ] Which task types does model struggle with?
- [ ] Context window limitations encountered?
- [ ] Tool-call success rate by adapter?

### Performance Gaps
- [ ] Average latency per adapter?
- [ ] Memory footprint on Mac (4GB allocated)?
- [ ] VRAM utilization (if GPU available)?
- [ ] Cache hit rates on rapid calls?

### Model Capability Gaps
- [ ] Multi-file editing support?
- [ ] Complex debugging tasks?
- [ ] Code generation quality (simple → complex)?
- [ ] Instruction following precision?

### Integration Gaps
- [ ] Ollama vs LM Studio feature parity?
- [ ] Proxy overhead on Ollama?
- [ ] Cold-start latency (first inference after load)?
- [ ] Context window exhaustion behavior?

---

## Decision Tree

```
Nightly Test Results
    ↓
├─ >80% average → GREEN: Proceed to Phase 1-5
├─ 70-80% average → YELLOW: Phase 1 + Phase 2 only
└─ <70% average → RED: Debug + retest
```

---

## Documentation Output

After each phase, update:
1. **qwen2.5-coder-7b-results.md** — Test results
2. **compat.json** — Auto-updated by bin/bench
3. **BENCHMARK-RESULTS.md** — Add to leaderboard
4. **docs/models/qwen--qwen2.5-coder-7b.md** — Create if >75% avg

---

## Commands Reference

View latest results:
```bash
ls -lt results/*/results.csv | head -1
tail -50 $(ls -t results/*/results.csv | head -1)
```

Compare adapters:
```bash
awk -F, 'NR>1 {a[$1]+=$4; t[$1]+=$5; c[$1]++} END {for(x in a) printf "%-10s %3d/%3d (%.0f%%)\n", x, a[x], t[x], 100*a[x]/t[x]}' results/*/results.csv | sort -rn -k3
```

Monitor in real-time:
```bash
watch -n 5 'wc -l results/*/results.csv | tail -5'
```

---

## Estimated Total Time

- Phase 1 (hard): 45 min
- Phase 2 (Ollama): 30 min
- Phase 3 (extended): 50 min
- Phase 4 (edge): 30 min
- Phase 5 (comparative): 75 min

**Total**: ~3.3 hours (can run phases in parallel)

**Start time**: Auto-triggered once nightly passes
