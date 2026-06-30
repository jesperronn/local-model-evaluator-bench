# qwen/qwen3.6-35b-a3b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.6-35b-a3b` |
| **Family / arch** | Qwen3.6, MoE (35B total, 3B active) |
| **Parameter count** | 35B total, 3B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-29 (run `20260629-005401`) |
| **LMS entry removed** | 2026-06-10 |
| **LMS entry re-added** | 2026-06-18 (qwen3.6-27b removed; 35b-a3b returned) |
| **Doc updated** | 2026-06-30 |

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

## Observations across runs

### 2026-06-29 — LMS overnight (run `20260629-005401`)

Full 11-adapter sweep on LMS. aider/cline/codex/goose/hermes/interpreter/opencode/openhands/pi all 38/38 (100%). Notable: aider now passes all multifile cases (js-03/js-04/js-06) that previously failed — confirmed improvement from the 2026-06-18 run. js-06 ran close to the 300s timeout on both aider (302s) and cline (301s) but passed. caveman and copilot confirmed LMS-incompatible (error(1) on all non-trivial cases; scores reflect partial pass on easy cases only).

### 2026-06-18 — LMS batch (runs `20260618-190652`, `20260618-190854`)

Four new adapters tested on LMS runtime: goose, interpreter, pi (all 36/36 100%, run `20260618-190652`), and cline (36/36 100%, run `20260618-190854` — the first cline run had error(1) on 3 cases due to binary init instability; see [cline.md](../tools/cline.md)). All perform identically to the best previous adapters. Model was re-added to `models.txt` after `qwen/qwen3.6-27b` was removed on 2026-06-12 for dominating performance gap. LMS now serves the MLX variant (not GGUF).

## Status

**keep** — perfect scores across all 8 adapters tested (aider, codex, opencode, caveman, hermes, pi, goose, interpreter, cline). Top-ranked model in the suite. Only aider shows adapter-specific failures (js-03, js-04, js-06 — known format issue).

**LMS entry history:** removed 2026-06-10 (replaced by qwen3.6-27b); re-added 2026-06-18 after qwen3.6-27b was removed for being strictly dominated (35.7% accuracy, 253s avg vs 94%+ and 48s avg for this model).

## Comparison within family

qwen3.6-35b-a3b vs qwen3-coder-30b:
- qwen3.6-35b-a3b achieves 100% on opencode/codex/caveman; qwen3-coder-30b is 97.1%/100%/100%
- The 35b-a3b is a general model; coder-30b is fine-tuned for code — for code tasks, both are near-identical
- For non-code tasks, 35b-a3b is likely stronger
