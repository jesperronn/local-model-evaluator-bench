---
title: "qwen3.8:27b-mlx (Ollama)"
model_key: "qwen3.8:27b-mlx"
family: "Qwen3.8"
params_total: "27B"
params_active: "27B (dense)"
quantization: "MLX 4-bit"
disk_size: "~18 GiB"
context: "256k"
status: "keep"
recommended_for: ["general-agentic-coding", "correctness-critical-edits"]
tier: "32gb"
best_adapter: "caveman"
accuracy: "90.5% (excl. smoke-00)"
speed_avg: "~113s per case (varies widely by adapter)"
added: "2026-08-15"
last_run: "2026-08-15 (20260815-113001)"
---

# qwen3.8:27b-mlx

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 90.5% across working adapters (pi 100%, caveman 100%, opencode 90.5%, aider 71.4%) |
| **Speed (avg)** | caveman ~101.5s/case (fastest at 100%); pi ~133.9s/case; opencode ~98.2s/case; aider ~140.2s/case |
| **Best adapter** | caveman — 100% accuracy at the best speed among 100%-scorers |
| **Recommended for** | general agentic coding on Ollama when correctness matters more than raw speed; NOT a fast daily driver |
| **Status** | keep |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `qwen3.8:27b-mlx` (Ollama tag) |
| **Family / arch** | Qwen3.8, dense (qwen3_5 arch) — successor to dense Qwen3.6-27B, **not** to MoE Qwen3.6-35B-A3B. No MoE/A3B sibling exists for this generation ([HF discussion](https://huggingface.co/Qwen/Qwen3.8-27B/discussions/43) asking Alibaba for one, unresolved as of 2026-08-15). |
| **Parameter count** | 27B total, 27B active (dense — every token walks all 64 layers) |
| **Quantization** | MLX 4-bit (group_size 64) |
| **Disk size** | ~18 GiB |
| **Context window** | 256k native |
| **Added** | 2026-08-15 |
| **Last run** | 2026-08-15 (run 20260815-113001) |
| **Doc updated** | 2026-08-15 |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| pi | 100% (42/42) | ~133.9s | ollama | Clean sweep, no failures. |
| caveman | 100% (42/42) | ~101.5s | ollama | Clean sweep, fastest among the 100% scorers. |
| opencode | 90.5% (38/42) | ~98.2s | ollama | One clean 0-score case (see Failure patterns). |
| aider | 71.4% (30/42) | ~140.2s | ollama | Diff-format struggles on this model (see Failure patterns). |

**Working adapters total:** 4/4
**Overall (incl. broken adapters):** 138/168 (82.1%; 90.5% excluding smoke-00 connectivity checks; 90.9%/160/176 incl. smoke-00 as originally reported)

## Timing observations

- Fastest adapter: opencode (~98.2s avg), closely followed by caveman (~101.5s).
- Slowest adapter: aider (~140.2s avg), driven by three near-timeout cases (js-02 301s, deleg-01 275s, js-05 302s timeout).
- Slow cases across all adapters: `js-05-multiselect-filter` and `ts-01-groupby` both regularly approach or hit the 300s ceiling (self-verify/iteration cases) — consistent with this being a dense 27B running at moderate tok/s, not a fast MoE model.
- Runtime note: this is the Ollama-served MLX quant. The oMLX-served copies of essentially the same weights are markedly slower and less reliable — see [docs/RUNTIME-OMLX.md](../RUNTIME-OMLX.md#dense-models-are-the-wrong-shape-for-omlx-under-timeout) and the sibling card [qwen--qwen3.8-27b-4bit-omlx.md](qwen--qwen3.8-27b-4bit-omlx.md).

## Failure patterns

- **aider, `deleg-01-validate-format-pipeline`** — 0/6 (275s). Aider-specific: aider's default SEARCH/REPLACE diff format struggles on this model's output style; pi/caveman/opencode all pass this case cleanly, so it is an adapter interaction, not a model-capability gap.
- **aider, `ts-01-groupby`** — 0/3 (180s). Same aider-specific pattern as above.
- **aider, `js-02-debounce-feature`** (3/4, 301s) and **`js-03-multifile-cache`** (3/5, 267s) — partial passes, both near the timeout ceiling; consistent with the same diff-format friction rather than a capability limit (other adapters pass both fully).
- **opencode, `bash-01-topwords`** — 0/4 (201s, stall). The only 0-score case for opencode; pi/caveman/aider all pass it, so this reads as an opencode/bash-tool interaction on this run rather than a repeatable model weakness — worth a retry to confirm before treating as systemic.

## Better alternatives

- If MoE speed matters more than this generation's accuracy bump, `qwen3.6-35b-a3b` (MoE, ~3B active) runs markedly faster per token at a slight accuracy cost — the two are genuinely different points on the speed/accuracy curve, not a strict dominance either way.
- For raw speed on a small dense model, `qwen3.5-9b` remains the fastest "keep" in this tier, at lower ceiling accuracy on harder multi-file cases.
- No smaller/cheaper model currently matches this one's 100% pi/caveman accuracy — for correctness-critical work at this size class, this is currently the best available.

## Status

**keep** — best available accuracy in this weight class via pi/caveman; use caveman or pi, avoid aider on this model until its diff-format issue is addressed. See [qwen--qwen3.8-27b-4bit-omlx.md](qwen--qwen3.8-27b-4bit-omlx.md) for why the omlx-served copies of the same weights should not be preferred over this ollama tag.

## Comparison within family

| Variant | Runtime | Accuracy (excl. smoke-00) | Avg speed | Verdict |
|---|---|---|---|---|
| `qwen3.8:27b-mlx` | ollama | 90.5% | ~113s (blended) | **preferred** |
| `Qwen3.8-27B-4bit` (Qwen org) | omlx | 68.9% | ~193s | slower, less reliable — same weights |
| `Qwen3.8-27B-4bit-mlxc` (mlx-community) | omlx | 80.0% | ~174s | slower, less reliable — same weights |
| `qwen3.8:27b-mtp-q4_K_M` | ollama | (not fully benched) | 3.80 tok/s vs 6.84 tok/s for this tag on the same prompt | **not recommended** — GGUF quant, MTP speedup doesn't materialize on ollama's backend |

## Observations across runs

- 2026-08-15 (run 20260815-113001): initial bench. See also `docs/RUNTIME-OMLX.md` for the oMLX-vs-ollama runtime comparison and the MTP-tag speed investigation logged in `TASKS.md`.
