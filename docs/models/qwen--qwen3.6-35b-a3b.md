---
title: "qwen/qwen3.6-35b-a3b"
model_key: "qwen/qwen3.6-35b-a3b"
family: "Qwen3.6"
params_total: "35B"
params_active: "3B"
quantization: "GGUF (LMS) / mxfp8 (Ollama)"
disk_size: "22.07 GiB"
context: "65536 loaded (256k max)"
status: "keep"
recommended_for: ["32gb", "32gb-balance", "64gb", "64gb-specialist", "128gb"]
tier: "32gb"
best_adapter: "aider"
accuracy: "100%"
speed_avg: "~24-64s per case"
added: "2026-06-08"
last_run: "2026-06-29"
---

# qwen/qwen3.6-35b-a3b

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% across working adapters |
| **Speed (avg)** | ~48s per case (3B active) |
| **Best adapter** | codex — fastest; cline — most reliable |
| **Recommended for** | general agentic coding, multi-file edits |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.6-35b-a3b` |
| **Family / arch** | Qwen3.6, MoE (35B total, 3B active) |
| **Parameter count** | 35B total, 3B active |
| **Quantization** | MLX (LMS) / mxfp8 (Ollama `qwen3.6:35b-a3b-coding-mxfp8`) |
| **Disk size** | 22.07 GB |
| **Context window** | 65536 loaded for bench (`BENCH_CONTEXT`); 256K max |
| **Fits** | Tight on 32GB: ~26.6GB at full 256K context — a squeeze. Obvious pick at 128GB; on 32GB run reduced context (see caveat) |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-29 (run `20260629-005401`) |
| **LMS entry removed** | 2026-06-10 |
| **LMS entry re-added** | 2026-06-18 (qwen3.6-27b removed; 35b-a3b returned) |
| **Doc updated** | 2026-06-30 |

## Prompt template compatibility

✓ **Fully multi-role prompting support** — This model's Jinja2 prompt template in LM Studio properly handles `system`, `user`, and `assistant` roles. This is critical for agentic adapters that require system instructions for tool definitions and agent context. Verified to work reliably across all major adapters (aider, cline, hermes, pi, opencode, etc.) without template conflicts.

## Results summary

The strongest general model in the suite. On the 2026-06-29 overnight run: aider, cline, codex, goose, hermes, interpreter, opencode, openhands, pi all scored **38/38 (100%)**. caveman and copilot are LMS-incompatible (not a model issue). Overall 366/406 (90%) including broken adapters; **100% across all working adapters**. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

| Adapter | 2026-06-29 (LMS) | Notes |
|---------|-----------------|-------|
| aider | 38/38 (100%) | Previously failed js-03/js-04/js-06; all now PASS |
| cline | 38/38 (100%) | |
| codex | 38/38 (100%) | |
| goose | 38/38 (100%) | |
| hermes | 38/38 (100%) | |
| interpreter | 38/38 (100%) | |
| opencode | 38/38 (100%) | |
| openhands | 38/38 (100%) | |
| pi | 38/38 (100%) | |
| nanocoder | 35/36 (97%) | js-04 0/1 (import not updated in consumer); all others PASS |
| caveman | 12/32 (37%) | LMS incompatible (error(1) — not model issue) |
| copilot | 12/32 (37%) | LMS incompatible (error(1) — not model issue) |

## Cross-runtime comparison (2026-07-02)

Full 11-case / 38-check suite run against matched weights on all three
runtimes — see [docs/runtimes/](../runtimes/) for the general per-runtime
writeups this data seeded.

| Adapter | LM Studio | Ollama (`qwen3.6:35b-mlx`) | MLX (`mlx_lm.server`) |
|---------|:---------:|:---------------------------:|:---------------------:|
| hermes | 100% | 89% | 100% |
| pi | 100% | 92% | 100% |
| interpreter | 100% | 100% | n/a (no mlx adapter) |
| opencode | 100% | 95% | 38% ⚠️ compat bug |
| openhands | 97% | 85% | n/a (no mlx adapter) |
| cline | 100% | n/a | 82% |
| codex | 92% | 89% | 38% ⚠️ compat bug |
| aider | 87% | 91% | 56% ⚠️ compat bug |
| copilot | 44% | n/a | 38% |
| caveman | 38% | n/a | 38% |

**MLX's low scores on aider/codex/opencode are a known adapter plumbing bug,
not a model or runtime issue** — see the "Known compat bug" callout in
[docs/runtimes/mlx.md](../runtimes/mlx.md). hermes and pi are unaffected and
score identically to lms, confirming MLX inference quality matches lms for
this model.

**Timing (avg seconds/case, adapters scoring ≥80% only):**

| Adapter | LM Studio | Ollama | MLX |
|---------|:---------:|:------:|:---:|
| pi | **29.5** | 95.4 | 52.4 |
| codex | 31.5 | 45.3 | — |
| interpreter | 43.1 | 73.6 | — |
| opencode | 52.4 | 129.2 | — |
| cline | 53.1 | — | 41.1 |
| openhands | 61.4 | 126.5 | — |
| aider | 71.3 | 72.5 | — |
| hermes | 97.4 | 83.5 | 105.8 |

LM Studio was fastest for every adapter comparable across runtimes except
hermes, where Ollama edged it out slightly. **pi + LM Studio is the best
speed/accuracy combo found for this model**: 100% at 29.5s/case.

## Better alternatives

No strictly better model currently identified for this workload; qwen3.6-35b-a3b is the primary recommendation for general agentic tasks in recent sweeps.

## Failure patterns

**caveman/copilot LMS incompatibility:** Both adapters fail with error(1) consistently (12/32 partial — only pass cases that don't require the adapter's specific tool call format). This is a caveman/copilot LMS compatibility issue, not a model issue. Both work on Ollama runtime.

**Historic (resolved) — aider multifile failures:** Earlier runs (pre-2026-06-29) showed aider failing js-03, js-04, and js-06 (multifile and self-verify cases). On the 2026-06-29 run all 11 cases passed 100%. Likely resolved by aider version update or adapter changes.

## Timing observations

> **Ollama note:** For Ollama runs, prefer `qwen3.6:35b-mlx` over
> `qwen3.6:35b-a3b-coding-mxfp8` — the MLX variant is ~3.3× faster (24s vs 81s
> avg on smoke tests). See [qwen--qwen3.6-35b-mlx.md](qwen--qwen3.6-35b-mlx.md).

- **hermes (Ollama):** 36–222s, avg ~83s. js-05-multiselect-filter at 222s was the slowest case. Otherwise 36–128s.
- **aider:** 38–130s. bash-01-topwords took 130s (slow for a 3B-active model; likely the model iterated on the shell pipeline).
- **opencode:** 45–93s. Consistent across cases.
- **codex:** 19–74s. Fastest of the non-aider adapters for this model.
- **caveman:** 24–69s. Similar to codex.
- **pi (LMS):** 6–68s. Fastest adapter of the 2026-06-18 batch. js-06 lint self-verify at 68s.
- **goose (LMS):** 18–110s. js-06 at 110s; otherwise 18–86s. No lingering observed.
- **interpreter (LMS):** 17–160s. bash-01-topwords slowest at 160s (OI writes shell code, then executes — cold Python startup adds overhead). Single-pass clean on all cases.
- **cline (LMS):** 31–300s. bash-01 slowest at 296s; js-05 at 292s; js-06 hit the 300s timeout (edit completed, harness killed process). Notably slower than other tool-call adapters — cline's agent loop has more turn overhead.

## Known issues

**hermes error(1) — historic (resolved 2026-06-11):** hermes was broken on all models; fixed by switching to `backend: local`. Results now available via Ollama (34/34 100%) and LMS hermes.

**MLX runtime model-id-as-path bug (open, found 2026-07-02):** aider, codex, and opencode collapse to 38–56% on `--runtime mlx` because the model is addressed by a raw filesystem path that their model-info lookup can't recognize (aider degrades context window; codex/opencode reject outright in ~2s). Not a model issue — hermes and pi score 100% on the same runtime/model. See [docs/runtimes/mlx.md](../runtimes/mlx.md).

## Observations across runs

### 2026-06-29 — LMS overnight (run `20260629-005401`)

Full 11-adapter sweep on LMS. aider/cline/codex/goose/hermes/interpreter/opencode/openhands/pi all 38/38 (100%). Notable: aider now passes all multifile cases (js-03/js-04/js-06) that previously failed — confirmed improvement from the 2026-06-18 run. js-06 ran close to the 300s timeout on both aider (302s) and cline (301s) but passed. caveman and copilot confirmed LMS-incompatible (error(1) on all non-trivial cases; scores reflect partial pass on easy cases only).

### 2026-06-18 — LMS batch (runs `20260618-190652`, `20260618-190854`)

Four new adapters tested on LMS runtime: goose, interpreter, pi (all 36/36 100%, run `20260618-190652`), and cline (36/36 100%, run `20260618-190854` — the first cline run had error(1) on 3 cases due to binary init instability; see [cline.md](../tools/cline.md)). All perform identically to the best previous adapters. Model was re-added to `models.txt` after `qwen/qwen3.6-27b` was removed on 2026-06-12 for dominating performance gap. LMS now serves the MLX variant (not GGUF).

## Status

**keep** — perfect scores across all 8 adapters tested (aider, codex, opencode, caveman, hermes, pi, goose, interpreter, cline). Top-ranked model in the suite. Only aider shows adapter-specific failures (js-03, js-04, js-06 — known format issue).

**LMS entry history:** removed 2026-06-10 (replaced by qwen3.6-27b); re-added 2026-06-18 after qwen3.6-27b was removed for being strictly dominated (35.7% accuracy, 253s avg vs 94%+ and 48s avg for this model).

## Thinking level / reasoning

**Model has reasoning capability:** Qwen3.6 includes native chain-of-thought via
`<think>` tokens in its chat template (accessible to all runners: LM Studio, Ollama,
llama.cpp, MLX, pi, caveman).

**Reasoning disabled by default in agentic adapters** for this benchmark — see
[adapters/pi-mlx.sh](../../adapters/pi-mlx.sh) and
[adapters/caveman-ollama.sh](../../adapters/caveman-ollama.sh) which pass
`--thinking off` to the CLI. LM Studio adapters strip reasoning via `/no_think`
system-prompt directives or "Model Reasoning Settings" GUI toggle.

**Why:** In agentic tool-loop workflows, reasoning burns tokens and latency with
minimal accuracy gain on surgical edits (100% accuracy already achieved at
reasoning-off). The deeper issue: Qwen3.6's "attention reinforcement trap"
causes reasoning to get stuck in **infinite loops** of self-doubt and
re-verification when iterating on code edits — see
[docs/troubleshooting-qwen-reasoning-loops.md](../troubleshooting-qwen-reasoning-loops.md).

**If you enable reasoning locally:**
- **Known issue:** Risk of attention reinforcement loops (endless re-verification
  of the same concern). **Workarounds needed:** fresh context, temperature
  0.6–0.7 (not 0), presence/frequency penalties 0.1–0.3, loop-blocking prompt
  directives. See [troubleshooting guide](../troubleshooting-qwen-reasoning-loops.md).
- **LM Studio (OpenAI-compatible):** Disable in model settings GUI under
  "Model Reasoning Settings," or append `/no_think` to system prompt.
- **llama.cpp:** Use `--chat-template-kwargs '{"preserve_thinking": false}' --jinja`
  to suppress `<think>` token leakage.
- **pi / caveman CLI:** Pass `--thinking on` (default is `off`).

**Recommended hyperparameter overrides if using reasoning:**
```bash
# Via config.sh or agent config apply:
# ADAPTER_DEFAULT_TEMPERATURE=0.65       # 0.6–0.7, avoid 0 (causes rigid loops)
# ADAPTER_DEFAULT_PRESENCE_PENALTY=0.15  # 0.1–0.3, penalizes repetitive tokens
# ADAPTER_DEFAULT_FREQUENCY_PENALTY=0.15 # Mitigates "Wait..." / "Actually..." loops
```

**Baseline (reasoning off, current default):** Full 100% accuracy; 48s avg per case.
Any reasoning-on tuning should target a latency reduction without accuracy loss.

## 32GB caveat & tuning notes

**Memory on 32GB:** at its max 256K context this model needs ~26.6GB, leaving
almost no headroom on a 32GB machine. It runs there only with heavily reduced
context (32K–64K). At that point [qwen3-coder-30b](qwen--qwen3-coder-30b-mlx.md)
(smaller KV footprint, code-tuned) is the more sensible 32GB target for surgical
edits. Reserve 35b-a3b's full context for the 128GB tier.

## Comparison within family

qwen3.6-35b-a3b vs qwen3-coder-30b:
- qwen3.6-35b-a3b achieves 100% on opencode/codex/caveman; qwen3-coder-30b is 97.1%/100%/100%
- The 35b-a3b is a general model; coder-30b is fine-tuned for code — for code tasks, both are near-identical
- For non-code tasks, 35b-a3b is likely stronger
