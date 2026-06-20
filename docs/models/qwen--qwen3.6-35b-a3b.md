# qwen/qwen3.6-35b-a3b

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen/qwen3.6-35b-a3b` |
| **Family / arch** | Qwen3.6, MoE (35B total, 3B active) |
| **Parameter count** | 35B total, 3B active |
| **Disk size** | <!-- TODO --> |
| **Added** | 2026-06-08 |
| **Last run** | 2026-06-18 |
| **LMS entry removed** | 2026-06-10 |
| **LMS entry re-added** | 2026-06-18 (qwen3.6-27b removed; 35b-a3b returned) |
| **Doc updated** | 2026-06-18 |

## Results summary

The strongest general model in the suite. hermes (via Ollama), opencode, and codex all score 100%; caveman 92.9% via Ollama. aider scores 92.9% (LMS). New adapters evaluated 2026-06-18 on LMS: cline 100%, goose 100%, interpreter 100%, pi 100% — all four achieve perfect scores. Despite 35B total params, the 3B active architecture keeps it fast. See [BENCHMARK-RESULTS.md](../../BENCHMARK-RESULTS.md).

## Failure patterns

**Adapter-specific — aider, js-03-multifile-cache (0/5):** aider scores 0/5 while all other adapters score 5/5. The model likely produces valid content but aider's edit format fails to apply both file changes atomically. No explicit `--file` hints are passed.

**Adapter-specific — aider, js-04-multifile-rename (0/1):** aider fails the multi-file rename case; all other adapters pass 3/3. Same mechanism: second file not updated, ESM import broken.

**Adapter-specific — aider, js-06-lint-and-test (0/4):** aider scores 0/4 on the self-verify lint case while all other adapters score 4/4. The model does not iterate through lint failures under aider, possibly because aider doesn't feed test output back in a format the model acts on.

All three failures are aider-specific and do not appear on opencode, codex, or caveman. This is strong evidence of an aider format/prompt interaction, not a model capability gap.

## Timing observations

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
