---
title: "Qwen3.8-27B-4bit (oMLX)"
model_key: "Qwen3.8-27B-4bit"
family: "Qwen3.8"
params_total: "27B"
params_active: "27B (dense)"
quantization: "MLX 4-bit"
disk_size: "~14-15 GiB"
context: "256k"
status: "watch"
recommended_for: []
tier: "32gb"
best_adapter: "caveman (mlxc copy) / aider (Qwen-org copy)"
accuracy: "68.9% (Qwen org) / 80.0% (mlx-community), excl. smoke-00"
speed_avg: "~193s (Qwen org) / ~174s (mlx-community) per case"
added: "2026-08-15"
last_run: "2026-08-15 (20260815-132035)"
---

# Qwen3.8-27B-4bit (oMLX)

Same weights/quant family as [qwen3.8:27b-mlx](qwen--qwen3.8-27b-mlx.md), served
via oMLX from two different re-uploads of the same checkpoint:
`Qwen/Qwen3.8-27B-4bit` and `mlx-community/Qwen3.8-27B-4bit`. Both resolved to
the same oMLX model id (`Qwen3.8-27B-4bit`) until 2026-08-15 — the
mlx-community copy's directory was renamed to `Qwen3.8-27B-4bit-mlxc` to break
the collision (see [docs/RUNTIME-OMLX.md](../RUNTIME-OMLX.md#gotcha-model-id-is-the-basename-only-org-is-invisible)).

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | Qwen-org copy 68.9%; mlx-community copy 80.0% (both excl. smoke-00) — same weights, single-trial gap, treat as noise until re-run |
| **Speed (avg)** | Qwen-org ~193s/case; mlx-community ~174s/case — both markedly slower than the ollama tag (~113s) |
| **Best adapter** | mlx-community copy + caveman (90.5%) is the strongest single combo; still below ollama's pi/caveman 100% |
| **Recommended for** | nothing specific — prefer [qwen3.8:27b-mlx](qwen--qwen3.8-27b-mlx.md) via ollama instead |
| **Status** | watch |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `Qwen3.8-27B-4bit` (Qwen org copy) / `Qwen3.8-27B-4bit-mlxc` (mlx-community copy, renamed to disambiguate) |
| **Family / arch** | Qwen3.8, dense (qwen3_5 arch) — see [qwen--qwen3.8-27b-mlx.md](qwen--qwen3.8-27b-mlx.md) for the dense-vs-MoE background |
| **Parameter count** | 27B total, 27B active (dense) |
| **Quantization** | MLX 4-bit (group_size 64) |
| **Disk size** | Qwen-org ~14 GiB; mlx-community ~15 GiB |
| **Context window** | 256k native |
| **Added** | 2026-08-15 |
| **Last run** | 2026-08-15 (run 20260815-132035) |
| **Doc updated** | 2026-08-15 |

## Results summary

### Qwen-org copy (`Qwen3.8-27B-4bit`)

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| aider | 76.2% (32/42) | ~140.9s | omlx | Best of the four here; still below its own ollama-tag baseline. |
| pi | 69.0% (29/42) | ~195.4s | omlx | Two stalls, one timeout on the hard cases. |
| opencode | 69.0% (29/42) | ~194.1s | omlx | Same pattern as pi. |
| caveman | 60.5% (23/38) | ~202.5s | omlx | Weakest — 5 stalled/failed cases including two self-verify cases at 0. |

### mlx-community copy (`Qwen3.8-27B-4bit-mlxc`)

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| caveman | 90.5% (38/42) | ~176.1s | omlx | Strongest combo for this copy. |
| pi | 85.7% (36/42) | ~188.2s | omlx | Good, but two hard cases still stall/timeout. |
| opencode | 71.1% (27/38) | ~196.8s | omlx | |
| aider | 71.1% (27/38) | ~136.6s | omlx | Fastest of the four despite mid-pack accuracy. |

**Working adapters total:** 4/4 (both copies)
**Overall (incl. broken adapters):** Qwen-org 113/164 (68.9%); mlx-community 128/160 (80.0%) — both excluding smoke-00; 121/172 (70.3%) and 136/168 (81.0%) respectively including smoke-00, as originally reported.

## Timing observations

- Both copies run at roughly **8 tok/s** on oMLX (measured via the oMLX dashboard) — versus the same weights running noticeably faster served through Ollama's own MLX backend. This is architectural (dense 27B = all params active every token), not model-specific — see [docs/RUNTIME-OMLX.md](../RUNTIME-OMLX.md#dense-models-are-the-wrong-shape-for-omlx-under-timeout) for the MoE comparison.
- The hard cases (`bash-01-topwords`, `deleg-01-validate-format-pipeline`, `ts-01-groupby`) repeatedly stall or hit the 300s ceiling across every adapter on both copies — the 300s/120s watchdog budget simply isn't enough headroom for this model at this speed on this runtime.
- js-* cases (single/few-file edits) mostly pass fine on both copies — the speed problem specifically bites the harder, longer-running cases.

## Failure patterns

- **All adapters, `bash-01-topwords`** — 0-scores or stalls across every adapter on both copies. This is the same case that passed cleanly via ollama, so it's a runtime-speed issue (timeout budget), not a model-capability gap.
- **caveman (Qwen-org copy), `js-05-multiselect-filter`** (0/1) and **`js-06-lint-and-test`** (0/4) — both stall at 180s; these are self-verify/iteration cases that need multiple turns, and the slow tok/s rate means caveman's iteration loop doesn't complete in time.
- The Qwen-org vs mlx-community accuracy gap (68.9% vs 80.0%) is **not attributed to a real weight/quant difference** — both are re-uploads of the same checkpoint. Treat this as run-to-run variance from single-trial timeouts landing differently, not a reason to prefer one upload over the other on quality grounds.

## Better alternatives

- **[qwen3.8:27b-mlx](qwen--qwen3.8-27b-mlx.md) via Ollama** is the same weights running faster and more reliably (90.5% vs 68.9-80.0%, ~113s vs ~174-193s avg) — prefer it over either omlx copy for this model.
- If oMLX's multi-model serving convenience matters more than speed for this specific model, the mlx-community copy (renamed `Qwen3.8-27B-4bit-mlxc`) is the better of the two uploads to keep — but expect worse timeout behavior on hard cases than the ollama tag.
- For MoE speed on oMLX specifically, `Qwen3.6-35B-A3B-MLX-4bit` and `Ornith-1.0-35B-4bit` are both markedly faster (256 experts, 8 active) and already in the default omlx sweep.

## Status

**watch** — kept in `~/.omlx/models` for occasional use, but not in the default `models-omlx.txt` sweep and not recommended over the ollama tag. Revisit if oMLX's dense-model throughput improves, or if a future oMLX release changes this picture materially.
