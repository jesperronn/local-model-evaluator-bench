# PLAN — Speculative decoding for agentic loops (investigation)

Status: **deferred / investigate** — created 2026-07-04, from field notes.

## The idea

Pair a large "target" model with a tiny fast "draft" model. The drafter proposes
several tokens ahead; the target verifies them in a single forward pass, accepting
the run up to the first disagreement. Net effect: fewer target forward passes per
token → higher tokens/sec with **identical** output to running the target alone
(speculative decoding is lossless when done correctly).

Field-note suggestion for this repo's agentic workflows:

- **Target (logic / surgical tool edits):** `qwen3-coder:30b`
- **Drafter (fast):** `granite4:3b` or `qwen2.5-coder:1.5b`

## Why it's a separate investigation (not a quick edit)

1. **Runtime support is the gating question.** Speculative decoding is a *serving*
   feature, not something this benchmark repo implements. Need to confirm which of
   our runtimes support it and how it's configured:
   - `llama.cpp` — `--model-draft` / `--draft` (supported)
   - `LM Studio` — check version; exposes it in some builds
   - `Ollama` — no first-class draft-model flag as of last check (verify)
   - `MLX` — check `mlx_lm` speculative support on Apple Silicon
2. **Drafter/target must share a tokenizer/vocab family** for accept rates to be
   good. `qwen2.5-coder:1.5b` + `qwen3-coder:30b` are close family-wise; a Granite
   drafter against a Qwen target is a mismatch — likely poor acceptance. Needs
   measurement, not assumption.
3. **Memory budget on 32GB.** Both models resident simultaneously. `qwen3-coder:30b`
   quantized (~18–20GB) + a 1.5B drafter (~1–2GB) may fit, but leaves little for
   context. Interacts with the [Apple Silicon VRAM cap tip](tools/hwprofile.md).
4. **It's a speed optimization, not a capability change** — so it needs a *benchmark*
   to justify: measure tokens/sec and acceptance rate with vs. without a drafter,
   on real agentic traces, before recommending it.

## Proposed investigation steps

- [ ] Inventory which repo runtimes expose a draft-model option (grep adapters / config.sh).
- [ ] Pick one runtime that supports it (likely `llama.cpp`).
- [ ] Bench `qwen3-coder:30b` alone vs. + `qwen2.5-coder:1.5b` drafter: tokens/sec,
      acceptance rate, peak memory. Reuse the existing bench harness.
- [ ] Test the Granite drafter too, to confirm/refute the cross-family penalty.
- [ ] If it wins on 32GB, document as a per-model card recommendation + a setup note;
      if it doesn't fit memory, note it as a 48GB+ tier optimization.

## Decision

Do **not** wire this into any script yet. Revisit as a benchmark task once runtime
support is confirmed. Output of the investigation → model card guidance +
`docs/HARDWARE-RECOMMENDATIONS.md` note, gated by tier.
