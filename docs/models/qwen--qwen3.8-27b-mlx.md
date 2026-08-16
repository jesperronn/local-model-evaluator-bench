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
best_adapter: "opencode"
accuracy: "91.1% (excl. smoke-00)"
speed_avg: "~117s per case (varies widely by adapter)"
added: "2026-08-15"
last_run: "2026-08-16 (20260816-113928)"
---

# qwen3.8:27b-mlx

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 91.1% across working adapters (pi 100%, caveman 100%, opencode 100%, aider 64.3%) |
| **Speed (avg)** | opencode ~104.8s/case (fastest at 100%); pi ~120.1s/case; caveman ~129.8s/case; aider ~114.1s/case |
| **Best adapter** | opencode — 100% accuracy at the best speed among 100%-scorers |
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
| **Last run** | 2026-08-16 (run 20260816-113928) |
| **Doc updated** | 2026-08-16 |

## Results summary

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| pi | 100% (42/42) | ~120.1s | ollama | Clean sweep, no failures. |
| caveman | 100% (42/42) | ~129.8s | ollama | Clean sweep. |
| opencode | 100% (42/42) | ~104.8s | ollama | Clean sweep, fastest among the 100% scorers — the prior run's `bash-01-topwords` 0-score did not reproduce (see Failure patterns). |
| aider | 64.3% (27/42) | ~114.1s | ollama | Diff-format struggles on this model persist and worsened slightly vs. the prior run (see Failure patterns). |

**Working adapters total:** 4/4
**Overall (incl. broken adapters):** 153/168 (91.1% excluding smoke-00 connectivity checks; 161/176, 91.5% incl. smoke-00)

## Timing observations

- Fastest adapter: opencode (~104.8s avg), followed by aider (~114.1s), pi (~120.1s), caveman (~129.8s, slowest this run despite being tied for top accuracy).
- Slow cases across all adapters: `js-05-multiselect-filter` and `ts-01-groupby` continue to regularly approach or hit the 300s ceiling (self-verify/iteration cases) — consistent with this being a dense 27B running at moderate tok/s, not a fast MoE model. aider's `js-05-multiselect-filter` hit a 302s timeout this run yet still scored 5/5 — the timeout fired after the deliverable was already complete.
- Runtime note: this is the Ollama-served MLX quant. The oMLX-served copies of essentially the same weights are markedly slower and less reliable — see [docs/RUNTIME-OMLX.md](../RUNTIME-OMLX.md#dense-models-are-the-wrong-shape-for-omlx-under-timeout) and the sibling card [qwen--qwen3.8-27b-4bit-omlx.md](qwen--qwen3.8-27b-4bit-omlx.md).

## Failure patterns

- **aider, `deleg-01-validate-format-pipeline`** — 0/6 (271s). Aider-specific: aider's default SEARCH/REPLACE diff format struggles on this model's output style; pi/caveman/opencode all pass this case cleanly, so it is an adapter interaction, not a model-capability gap. Reproduced from the 2026-08-15 run.
- **aider, `ts-01-groupby`** — 0/3 (153s). Same aider-specific pattern, reproduced from the prior run.
- **aider, `js-02-debounce-feature`** — 0/4 (157s). Full failure this run (was a 3/4 partial in the 2026-08-15 run) — same diff-format friction, slightly worse outcome.
- **aider, `js-03-multifile-cache`** — 3/5, 60% (288s, near timeout ceiling) — partial pass, consistent with the same diff-format friction rather than a capability limit (other adapters pass it fully).
- **opencode, `bash-01-topwords`** — passed cleanly this run (4/4), confirming the 2026-08-15 0-score was a one-off opencode/bash-tool interaction rather than a repeatable model weakness, as flagged at the time.
- **opencode, `js-02-debounce-feature`** and **`ts-01-groupby`** — both logged `status=error` but still scored full marks (4/4, 3/3); worth a retry to confirm this error path is benign (e.g. a late non-fatal tool error after the deliverable already passed) rather than a masked issue.

## Better alternatives

- If MoE speed matters more than this generation's accuracy bump, `qwen3.6-35b-a3b` (MoE, ~3B active) runs markedly faster per token at a slight accuracy cost — the two are genuinely different points on the speed/accuracy curve, not a strict dominance either way.
- For raw speed on a small dense model, `qwen3.5-9b` remains the fastest "keep" in this tier, at lower ceiling accuracy on harder multi-file cases.
- No smaller/cheaper model currently matches this one's 100% pi/caveman accuracy — for correctness-critical work at this size class, this is currently the best available.

## Status

**keep** — best available accuracy in this weight class via pi/caveman/opencode (all 100%); prefer opencode for speed, avoid aider on this model until its diff-format issue is addressed (worsened slightly this run: 64.3% vs. 71.4% previously). See [qwen--qwen3.8-27b-4bit-omlx.md](qwen--qwen3.8-27b-4bit-omlx.md) for why the omlx-served copies of the same weights should not be preferred over this ollama tag.

## Comparison within family

| Variant | Runtime | Accuracy (excl. smoke-00) | Avg speed | Verdict |
|---|---|---|---|---|
| `qwen3.8:27b-mlx` | ollama | 91.1% | ~117s (blended) | **preferred** |
| `Qwen3.8-27B-4bit` (Qwen org) | omlx | 68.9% | ~193s | slower, less reliable — same weights |
| `Qwen3.8-27B-4bit-mlxc` (mlx-community) | omlx | 80.0% | ~174s | slower, less reliable — same weights |
| `qwen3.8:27b-mtp-q4_K_M` | ollama | (not fully benched) | 3.80 tok/s vs 6.84 tok/s for this tag on the same prompt | **not recommended** — GGUF quant, MTP speedup doesn't materialize on ollama's backend |

## Observations across runs

- 2026-08-15 (run 20260815-113001): initial bench. See also `docs/RUNTIME-OMLX.md` for the oMLX-vs-ollama runtime comparison and the MTP-tag speed investigation logged in `TASKS.md`.
- 2026-08-16 (run 20260816-113928): re-bench, full 4-adapter x 12-case matrix. Accuracy ticked up slightly (91.1% vs 90.5% excl. smoke-00) — opencode's one prior failure (`bash-01-topwords`) did not reproduce, moving opencode to a clean 100% sweep and making it the new fastest 100%-scorer (~104.8s), displacing caveman (which slowed to ~129.8s this run, still 100% accurate). aider held steady in the low-60s/70s% band on its known diff-format weakness, and got slightly worse (64.3% vs 71.4%) with one previously-partial case (`js-02-debounce-feature`) failing outright this time. Run-to-run adapter timing swings (caveman +28s, opencode -6.6s vs. prior avg) are consistent with single-trial variance noted elsewhere in this repo — no `--trials >1` was used for either run, so treat small deltas as noise and the overall accuracy tiering (pi/caveman/opencode 100%, aider well behind) as the stable signal.
