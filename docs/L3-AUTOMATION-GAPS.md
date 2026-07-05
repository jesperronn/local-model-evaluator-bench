# L3 Automation & Gap Analysis

**Status:** Current state analyzed 2026-07-05. No automation added yet — documentation-first approach recommended.

---

## Current State: bin/stale + bin/bench-overnight

### What Exists

**bin/stale** — Identifies what NEEDS rerunning:
- `missing`: never run for this runtime
- `failed`: last result status wasn't "ok"
- `stale`: inputs changed after run started
- Output: CSV → can feed to `bin/bench-overnight --worklist`

**bin/bench-overnight** — Runs L3 (multiple trials):
- Default: runs hardcoded models with 3+ trials
- Worklist mode: `--stale` or `--worklist FILE` to drive from missing/failed/stale
- Restarts services between models (cleanliness)

### Current Workflow

```bash
bin/bench-overnight --stale  # find stale/missing/failed, run them with --trials 3+
```

This covers **reactive rerunning** (what broke, retest it).

---

## What's NOT Automated: Performance-Based Promotion

### Gap 1: No L2→L3 Promotion Decision

**bin/stale finds:** What NEEDS rerunning (missing/failed/stale)

**Missing:** Tool to identify "this L2 combo achieved 95% pass rate, promote to L3"

**Current workflow:** Manual review of L2 results to pick L3 candidates

### Gap 2: No "Ready for L3" Manifest

To promote L2 → L3 manually, you must:
1. Review `results/*/results.csv` (find high-scoring combos)
2. Identify combos with score > threshold (e.g., 0.90)
3. Build a `--worklist` CSV by hand (or via grep/awk)
4. Pass to `bin/bench-overnight --worklist`

### Gap 3: No Auto-Decision on L3 Threshold

L3 is "confidence grade" — multiple trials to get median. But when is a combo "confident enough"?

**Current decision:** Hardcoded "top adapters" in DEFAULT_OVERNIGHT_MODELS (aider, cline, hermes, opencode, pi)

---

## Three Options to Close the Gap

### Option A: Create `bin/promote-to-l3` (New Tool)

Read L2 results, identify candidates for L3 based on score threshold, output worklist CSV.

```bash
# Pseudocode
bin/promote-to-l3 --from-run 20260705-000000 --threshold 0.90 > l3-candidates.csv
bin/bench-overnight --worklist l3-candidates.csv
```

**Effort:** Medium (~100 lines bash)
**Benefit:** Automation + transparency of L3 selection
**When:** After L2 runs complete regularly

### Option B: Document L3 Criteria (No Code)

Update TESTING-STRATEGY.md with clear rules so L3 promotion is documented but manual:
- L2 combos with score ≥ 0.90 across all cases
- OR top N adapters (aider, cline, hermes, opencode, pi)
- Review weekly, promote manually to L3

**Effort:** Low (~30 min)
**Benefit:** Clarity, no code maintenance
**When:** Now (blocking nothing)

### Option C: Enhance `bin/bench-overnight` (Integrated)

Add a flag like `--promote-from RUN_ID --threshold 0.90` that:
1. Reads a previous L2 run
2. Extracts high-scoring combos
3. Runs them with --trials 3+

**Effort:** Medium (~150 lines bash)
**Benefit:** One-command workflow
**When:** After L2 run cadence stabilizes

---

## What bin/stale Covers vs. Doesn't

### ✓ Detects Changes In:
- config.sh, lib/common.sh, bin/bench (affects all combos)
- adapters/<name>-<runtime>.sh (adapter-specific)
- cases/<case>/* (case-specific)
- bin/pi-patch-edit-shim (pi/caveman only)

### ✗ Does NOT Detect:
- Model availability changes (missing model)
- Runtime version changes (lms/ollama/mlx upstreamchanges)
- Hardware changes (RAM, CPU)
- compat.json updates (new breakages)

---

## Recommendation

**L3 automation is NOT missing — it has two working modes:**

1. **Reactive (stale):** `bin/bench-overnight --stale` → finds what broke, reruns with confidence
2. **Manual (performance):** Review L2 results, pick winners, run with --trials 3+

**The gap is visibility:** No tool answers "which L2 combos should graduate to L3?"

**Best path forward:**

1. **Now:** Implement **Option B** (documentation) — 30 min, zero code debt
   - Add L3 promotion criteria to TESTING-STRATEGY.md
   - Clarify: "Score ≥ 0.90 → eligible for L3"

2. **Later:** Consider **Option A** (bin/promote-to-l3) if L2 runs become frequent
   - Worth doing once L2 is a regular workflow (weekly+)

3. **Skip:** Option C (integrated) — adds complexity, Option B achieves same goal

---

## Next Steps

1. Update TESTING-STRATEGY.md with L3 promotion criteria (under "When to start where")
2. Track which L2 combos hit 0.90+ score
3. Run those with `--trials 3+` manually or via `--worklist`
4. If workflow becomes burdensome, implement `bin/promote-to-l3`

---

## Related Documentation

- [TESTING-STRATEGY.md](TESTING-STRATEGY.md) — Full testing funnel design
- [bin/stale](../bin/stale) — Identifies stale/missing/failed combos
- [bin/bench-overnight](../bin/bench-overnight) — L3 runner
