# Evaluation Question Suite (100 questions)

> **Purpose.** A repeatable test set for two things:
> 1. **Findability / decision support** — can an agent or human start at the top
>    of the repo and drill down to find the *best* (agent × model × runtime)
>    combo, where **accuracy wins and speed breaks ties**?
> 2. **Doc consistency** — sections **C, D, E** are the canonical question set
>    that *every* model card / tool card / runtime card must be able to answer.
>    Run them against every card; a card that can't answer one is a doc gap to
>    fix in round 2.
>
> Each question lists the **expected answer** and the **source** that grounds it.
> "Source" is where the answer *should* live — if it isn't there, that's a finding.
>
> Round 1 = this suite. Round 2 = rewrite docs that fail it.

**Legend for source paths:** all relative to repo root.

---

## A. Navigation & progressive disclosure (12)

Tests whether someone can enter at the top and reach the right detail without
already knowing the layout.

1. **Starting from the README alone, where do I learn the project's end goal?**
   → README "End goal": a multi-agent orchestration setup (orchestrator + 2–3
   agents) at `--parallel 3–4`. *Source: [README.md](../README.md) §End goal.*

2. **From the top, how do I get to per-model results without reading every file?**
   → README §Documentation links to `LEADERBOARD.md` and `docs/models/*.md`;
   `docs/AGENT-SELECTION.md` has the per-model matrix. *Source: [README.md](../README.md) §Documentation.*

3. **Which single doc gives the complete add-adapter → run → interpret workflow?**
   → `docs/WORKFLOW.md`. *Source: [README.md](../README.md) §Documentation → [docs/WORKFLOW.md](WORKFLOW.md).*

4. **Where is the four-stage pipeline (start → ingest → evaluate → visualize) described, and what command runs each stage?**
   → README §Pipeline: `bin/bench`, `bin/report --all`, `bin/gen-evals`, `bin/viz`.
   *Source: [README.md](../README.md) §The pipeline.*

5. **I have an M2 Max 32 GB. Where do I find what to run, end to end?**
   → `docs/HARDWARE-RECOMMENDATIONS.md` §M2 Max 32 GB (model + adapter + config.sh tuning).
   *Source: [docs/HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md).*

6. **From the README, how do I find the precise spec of a single test case?**
   → README §Documentation → `docs/CASES.md` (one section per case).
   *Source: [docs/CASES.md](CASES.md).*

7. **Where do I find the list of every script and a one-line description of each?**
   → README §All scripts (Core pipeline / Iteration & debugging / Maintenance / Adapter tooling).
   *Source: [README.md](../README.md) §All scripts.*

8. **A model card mentions a sibling — can I navigate to it?**
   → Yes; cards cross-link siblings inline (e.g. qwen3.6-35b-a3b links to
   qwen3.6-35b-mlx). *Source: [docs/models/qwen--qwen3.6-35b-a3b.md](models/qwen--qwen3.6-35b-a3b.md).*

9. **Where is the canonical structure a model/tool/runtime card must follow?**
   → `docs/templates/` (3 templates) **and** `docs/MODEL-EVAL-REQUIREMENTS.md` /
   `docs/TOOL-EVAL-REQUIREMENTS.md`. *Source: [docs/templates/README.md](templates/README.md).*
   ⚠️ Finding: two sources of truth exist; they diverge (see Q98).

10. **How do I find which adapter+model combos are known-broken before I run?**
    → `compat.json` + `docs/WORKFLOW.md` §5; `bin/bench` auto-skips status="open".
    *Source: [docs/WORKFLOW.md](WORKFLOW.md) §5.*

11. **Where do candidate models (not yet benchmarked) and their sources live?**
    → `docs/MODEL-RESEARCH.md` (dated log with re-runnable search queries).
    *Source: [docs/MODEL-RESEARCH.md](MODEL-RESEARCH.md).*

12. **From the README, how do I reach IDE-extension (Cline/Continue) guidance?**
    → README §Documentation → `docs/extensions/` (start with cline.md).
    *Source: [docs/extensions/README.md](extensions/README.md).*

---

## B. Decision & conceptual questions (24)

The core "help me choose" axis. Accuracy first, speed as tiebreaker.

13. **What is the single headline question the whole project answers?**
    → The smallest/fastest local model that reliably passes at realistic
    concurrency, and which tool gets the most out of it. *Source: [README.md](../README.md) §Purpose.*

14. **When two models have equal accuracy, which do I pick?**
    → The faster one (stated rule on every card's Quick verdict). *Source: [docs/templates/model-card-template.md](templates/model-card-template.md).*

15. **When two tools have equal accuracy, which do I pick?**
    → The faster one. *Source: [docs/templates/tool-card-template.md](templates/tool-card-template.md).*

16. **What is the current top-ranked general model in the suite, and why?**
    → qwen3.6-35b-a3b — 100% across all working adapters; MoE 3B-active keeps it fast.
    *Source: [docs/models/qwen--qwen3.6-35b-a3b.md](models/qwen--qwen3.6-35b-a3b.md) §Status.*

17. **What's the fastest adapter overall, and on what model?**
    → aider, ~11s avg on qwen3-coder-30b. *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md) §Speed-Critical.*

18. **I need <30s/case. What combo should I run?**
    → aider + qwen3-coder-30b (~11s) or aider + qwen3.6-35b-a3b (~40s).
    *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md) §Speed-Critical.*

19. **I need maximum accuracy on complex tasks even if slow. What tool?**
    → cline (100% on 35b-a3b / 9b; slower on complex cases). *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md).*

20. **Why is "biggest model" the wrong default for local use?**
    → Every extra GB is RAM you don't have; every extra second multiplies across
    all agents. *Source: [README.md](../README.md) §Purpose.*

21. **Which model architectures does the project prefer, and why?**
    → MLX-native, MoE/A3B, QAT, MTP — they keep a large local model fast enough
    to be worth running. *Source: [README.md](../README.md) §Design criteria #4.*

22. **What's the decisive factor separating fast from slow models in benchmarks?**
    → MoE vs Dense (sparse active params). *Source: [docs/HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) §MoE vs Dense.*

23. **Why does the bench run at `--parallel 3` by default?**
    → It mirrors the target workload (orchestrator + 2–3 agents); config.sh sets
    `BENCH_PARALLEL=3`. *Source: [README.md](../README.md) §`--parallel` note.*

24. **A model scores well at `--parallel 1` but degrades at `--parallel 4`. Verdict?**
    → Not a good fit for a multi-agent setup. *Source: [README.md](../README.md) §`--parallel` note.*

25. **What's the recommended primary model + config for an M5 Max 128 GB?**
    → See HARDWARE-RECOMMENDATIONS §M5 Max 128 GB (model selection + config.sh tuning).
    *Source: [docs/HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) §M5 Max 128 GB.*

26. **On a 32 GB machine, what changes vs 128 GB?**
    → Smaller models, `BENCH_PARALLEL=2`, `BENCH_CONTEXT=65536`. *Source: [docs/HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) §M2 Max 32 GB.*

27. **Does the MLX variant of a model change accuracy or just speed?**
    → Speed (≈3.3× faster on Apple Silicon); accuracy equal. *Source: [docs/models/qwen--qwen3.6-35b-a3b.md](models/qwen--qwen3.6-35b-a3b.md) §Timing.*

28. **Why does tool choice matter as much as model choice?**
    → Especially on smaller models, the adapter determines how much accuracy/speed
    you extract. *Source: [README.md](../README.md) §Purpose.*

29. **Which adapters are LMS-incompatible and only work on Ollama?**
    → caveman, copilot (error(1) on LMS). *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md) matrix.*

30. **Why keep weak/low-accuracy adapters in the suite at all?**
    → Data completeness: comparative insight, failure patterns, research value.
    *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md) §Why Keep Weak Agents.*

31. **For a single accuracy+speed-balanced production pick, what's recommended?**
    → aider or interpreter. *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md) §Production.*

32. **Which model is viable only on codex and times out elsewhere?**
    → glm-4.7-flash (codex 65%; everything else at timeout floor 37%). *Source: [docs/AGENT-SELECTION.md](AGENT-SELECTION.md) per-model.*

33. **Why must Hermes be loaded with ≥64K context?**
    → Hermes hard-refuses <64K and aborts in ~3s, zeroing every trial; config.sh
    sets `BENCH_CONTEXT=65536`. *Source: [README.md](../README.md) §Context window note.*

34. **How should quantization be chosen?**
    → Match it to the workload (accuracy vs speed vs context). *Source: [docs/SETUP.md](SETUP.md) §Which quantization.*

35. **What is the next layer of cases beyond the current single-agent ones?**
    → Multi-agent: orchestrator + sub-agents, concurrent tool calls, hand-off.
    *Source: [README.md](../README.md) §End goal.*

36. **When a pass-rate alone can't explain a result, what do I do?**
    → Inspect actual tool calls via `bin/trace-edit` / `bin/trace-tool-calls`.
    *Source: [README.md](../README.md) §pipeline; [docs/tools/pi.md](tools/pi.md).*

---

## C. Model-card template questions — EVERY `docs/models/*.md` must answer (18)

Run all 18 against each model card. A blank/missing answer is a doc gap.
Canonical source: [docs/CARD-SPEC.md](CARD-SPEC.md) → "Model card".

37. **Quick verdict: accuracy?** → e.g. "100% across working adapters." *(Quick verdict table)*
38. **Quick verdict: average speed?** → must be filled; "unknown" is unacceptable. *(Quick verdict; §Rule)*
39. **Quick verdict: best adapter?** → e.g. "codex — fastest; cline — most reliable." *(Quick verdict)*
40. **Quick verdict: recommended for?** → task class, e.g. "multi-file edits." *(Quick verdict)*
41. **Quick verdict: status (keep / watch / drop)?** → one word + rationale. *(Quick verdict + §Status)*
42. **What is the exact model key/identifier?** → as used in adapters/bench. *(Metadata)*
43. **Family / architecture?** → e.g. "Qwen3.6, MoE." *(Metadata)*
44. **Parameter count (total + active)?** → e.g. "35B total, 3B active." *(Metadata)*
45. **Quantization?** → e.g. "GGUF Q4_K_M / MLX 6-bit." *(Metadata)*
46. **Disk size?** → GB. *(Metadata)* ⚠️ qwen3.6-35b-a3b has this as TODO (Q97).
47. **Context window?** → e.g. "128k." *(Metadata)*
48. **Dates: Added / Last run (+ run ID) / Doc updated?** → three dates. *(Metadata)*
49. **Per-adapter results: accuracy + speed + runtime?** → the Results-summary table. *(Results summary)*
50. **Working-adapters total and overall-incl-broken totals?** → e.g. "9/11" and "366/406 (90%)." *(Results summary)*
51. **Timing: fastest adapter, slowest adapter, slow cases, runtime note — in absolute seconds?** *(Timing observations)*
52. **Documented repeatable failure patterns (with cause)?** → or explicitly none. *(Failure patterns)*
53. **Comparison to closest sibling (accuracy vs speed) and which to prefer when?** *(Comparison within family)*
54. **Observations log per run batch (newest first, with run ID)?** *(Observations across runs)*

---

## D. Tool-card template questions — EVERY `docs/tools/*.md` must answer (16)

Canonical source: [docs/CARD-SPEC.md](CARD-SPEC.md) → "Tool card".

55. **Quick verdict: accuracy (on which model)?** *(Quick verdict)*
56. **Quick verdict: average speed?** → must be filled. *(Quick verdict; §Rule)*
57. **Quick verdict: best model?** *(Quick verdict)*
58. **Quick verdict: recommended for?** *(Quick verdict)*
59. **Quick verdict: status (stable / experimental / broken)?** *(Quick verdict + §Status)*
60. **CLI command and version?** *(Metadata)*
61. **Which adapter script drives it (linked)?** *(Metadata)*
62. **How it connects to the local server?** → e.g. OpenAI-compat via `--baseurl`. *(Metadata)*
63. **Last reviewed date?** *(Metadata)*
64. **Edit format?** → tool calls / search-replace / unified diff / whole-file. *(Edit mechanism)*
65. **File targeting mechanism?** → autonomous / explicit path / git-diff. *(Edit mechanism)*
66. **Multi-file edit support (native / limited / none)?** *(Edit mechanism)*
67. **Self-verify / iteration behaviour (loops or single-pass)?** *(Iteration / self-verify)*
68. **Per-model results table (sorted accuracy desc, speed asc)?** *(Results by model)*
69. **Adapter flags and the reason for each?** *(Adapter flags / setup)*
70. **Documented repeatable failure modes with root cause?** *(Failure modes)*
70b. **Critical-path capability flags?** → explicitly states if tool-editing is
   dubious or a category (e.g. bash editing) is stuck, or "no known blockers."
   *(Capability notes — required; replaces the dropped per-case breakdown.)*

---

## E. Runtime-card template questions — EVERY runtime card must answer (8)

Canonical source: [docs/CARD-SPEC.md](CARD-SPEC.md) → "Runtime card".
⚠️ Finding: no `docs/runtimes/` directory exists yet — runtime cards are not
written, so E is currently aspirational (see Q100).

71. **Quick verdict: accuracy impact vs baseline?** *(Quick verdict)*
72. **Quick verdict: speed vs baseline (e.g. ×lms)?** → must be filled. *(Quick verdict; §Rule)*
73. **Best model class for this runtime?** *(Quick verdict)*
74. **CLI/binary, version, base URL, API compatibility?** *(Metadata)*
75. **Connection setup (env vars, base-URL quirks like /v1 stripping)?** *(Connection setup)*
76. **Performance vs baseline per model class (with numbers)?** *(Performance characteristics)*
77. **Which model formats are supported (GGUF/MLX/bf16/AWQ)?** *(Supported model formats)*
78. **Per-adapter compatibility (✅/❌ + note)?** *(Adapter compatibility)*

---

## F. Scoring & methodology (12)

79. **What is the primary score?** → objective test pass-rate (fraction of
    assertion points). *Source: [docs/SCORING.md](SCORING.md) §Primary score.*
80. **What is recorded co-equally with accuracy?** → wall-clock seconds (`med s`).
    *Source: [docs/SCORING.md](SCORING.md) §Speed.*
81. **What does `--trials N` record, and why?** → the median (variance is material;
    a triple can swing 4/4→0/4). *Source: [docs/SCORING.md](SCORING.md) §Trials and medians.*
82. **Where does per-trial detail land vs the median?** → `trials.csv` vs
    `results.csv`. *Source: [README.md](../README.md); [docs/SCORING.md](SCORING.md).*
83. **What outputs does a run produce and where?** → `results/<ts>/results.csv`
    + per-tool sandbox with `.bench.log`, traces/. *Source: [README.md](../README.md) §pipeline.*
84. **What makes a "good case"?** → see SCORING §What a good case looks like.
    *Source: [docs/SCORING.md](SCORING.md).*
85. **How are workarounds / write-fallbacks handled for fairness?** → SCORING
    §Workarounds and fairness. *Source: [docs/SCORING.md](SCORING.md).*
86. **What is the gated funnel L0→L3 and what runs at each level?** → L0 wiring
    (smoke) → L1 qualify+prune → L2 core bench → L3 confidence. *Source: [docs/TESTING-STRATEGY.md](TESTING-STRATEGY.md).*
87. **What is dominance pruning (L1b) and is it inference-free?** → arithmetic
    elimination of strictly-dominated combos, no inference. *Source: [docs/TESTING-STRATEGY.md](TESTING-STRATEGY.md) §L1b.*
88. **How is accuracy defined precisely?** → fraction of assertion points earned
    by the hidden grader. *Source: [docs/SCORING.md](SCORING.md); [docs/CASES.md](CASES.md) §grader contract.*
89. **Is the LLM-judge quality score active?** → No, not yet wired (optional secondary).
    *Source: [docs/SCORING.md](SCORING.md) §Optional secondary.*
90. **What categories and difficulty levels do cases have?** → bugfix/feature/
    multi-file/self-verify/cli/smoke; difficulty field. *Source: [docs/CASES.md](CASES.md) §Categories, §Difficulty.*

---

## G. Process / workflow (10)

91. **How do I add a new model to the bench?** → download in LM Studio, add its id
    to `models.txt`. *Source: [README.md](../README.md) §Adding things; [docs/WORKFLOW.md](WORKFLOW.md) §2.*
92. **How do I add a new adapter (CLI)?** → drop `adapters/<name>.sh` per the
    contract, update config.sh, smoke test, check compat.json. *Source: [docs/WORKFLOW.md](WORKFLOW.md) §1.*
93. **How do I add a new test case?** → copy a `cases/<id>/` folder. *Source:
    [docs/ADDING-CASES.md](ADDING-CASES.md).*
94. **What does `bin/smoke` classify each adapter as?** → PASS / PARTIAL (reached
    model, didn't finish) / FAIL (couldn't reach model). *Source: [README.md](../README.md) §Quick start.*
95. **What is the recommended first step on a new machine?** → `bin/smoke` after
    `lms server start` + `bin/doctor`. *Source: [README.md](../README.md) §Quick start.*
96. **How do I mark / re-evaluate an abandoned adapter?** → WORKFLOW §5c (mark)
    and §6 (re-evaluate after fix/upgrade). *Source: [docs/WORKFLOW.md](WORKFLOW.md) §5–6.*

---

## H. Meta-consistency findings to resolve in round 2 (4)

These are questions the suite *surfaced* — they're doc-quality defects, listed so
round 2 has a punch list.

97. **Do all model cards fill every required Metadata field?** → was No
    (qwen3.6-35b-a3b had Disk size = TODO, no Context window). ✅ **FIXED round 2**
    (Disk size 22.07 GB, Context window 65536, Quantization added). ⚠️ Sibling
    qwen3.6-35b-mlx still has TODO gaps — deferred to the full card sweep.
    *Source: [docs/models/qwen--qwen3.6-35b-a3b.md](models/qwen--qwen3.6-35b-a3b.md).*

98. **Do the templates and the *-EVAL-REQUIREMENTS docs agree on section names?**
    → was No (two diverging sources of truth). ✅ **RESOLVED round 2**: merged into
    one canonical doc [docs/CARD-SPEC.md](CARD-SPEC.md); old templates + requirements
    are now redirect stubs. *Source: [docs/CARD-SPEC.md](CARD-SPEC.md).*

99. **Do real cards include the "Quick verdict" table the spec mandates?**
    → **No — 0 of 23 model cards and 0 of 17 tool cards have it** (audited
    2026-06-30). Decision: Quick verdict stays **mandatory**; backfill all 40 via
    the smaller-model card sweep (tooling TBD). **OPEN — sweep pending.**
    *Source: audit of docs/models/*.md + docs/tools/*.md.*

100. **Does a runtime card exist for every runtime referenced (lms/ollama/mlx)?**
     → No `docs/runtimes/` directory exists; section E aspirational. Spec is ready
     in [docs/CARD-SPEC.md](CARD-SPEC.md) → "Runtime card". **OPEN — create cards.**
     *Source: repo tree.*

---

### How to use this suite

- **As a findability eval:** give a model only the repo and ask A + B; score
  whether it reaches the right doc and the right answer.
- **As a consistency gate:** for each card, run its section (C / D / E). Every
  unanswerable question = a required edit. Track pass-rate per card over time.
- **Round 2:** start with section H (the four known defects), then sweep every
  card against C/D so all cards answer the same questions identically.
