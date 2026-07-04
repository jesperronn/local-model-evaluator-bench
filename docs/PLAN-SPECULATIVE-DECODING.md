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

- [x] Inventory which repo runtimes expose a draft-model option (grep adapters / config.sh).
- [ ] Pick one runtime that supports it → `mlx_lm.server` (only automatable target; LM Studio is UI-only, Ollama unsupported).
- [ ] Bench `qwen3-coder:30b` alone vs. + `qwen2.5-coder:1.5b` drafter: tokens/sec,
      acceptance rate, peak memory. Reuse the existing bench harness.
- [ ] Test the Granite drafter too, to confirm/refute the cross-family penalty.
- [ ] If it wins on 32GB, document as a per-model card recommendation + a setup note;
      if it doesn't fit memory, note it as a 48GB+ tier optimization.

## Runtime support (findings)

**Inventory completed 2026-07-04.** This repo uses three runtimes: `lms` (LM Studio), `mlx_lm.server`, and `ollama`. 
`llama.cpp` is **not used** in this repo's adapters — all adapters target one of the three above.

| Runtime | Draft-model flag | API parameter | Supported? | Notes |
|---------|------------------|----------------|:----------:|-------|
| **lms** (LM Studio) | UI-only in sidebar | None (OpenAI `/v1` API) | ✅ Yes | LM Studio 0.3.10+ supports speculative decoding. Draft model is selected via UI "Speculative Decoding" sidebar after loading the main model. **Command-line / API-level configuration not exposed** — requires graphical selection or programmatic use of LM Studio's Node.js SDK. Version 0.4.14 (2026) adds MTP (multi-token prediction) support for models with built-in prediction heads (DeepSeek-V3, DeepSeek-R1). |
| **mlx_lm.server** | CLI flag | `draft_model` (server), `num_draft_tokens` | ✅ Yes | `mlx_lm.server` supports speculative decoding via `draft_model` parameter (string: model ID or `null`) and `num_draft_tokens` (int, default 3). Known limitation: "SpeculativeDecodingNotSupportedError" when batching is enabled on some model combinations; MoE models can see 35% performance regression if draft size is close to MoE active param count. |
| **ollama** | None | None | ❌ No | Ollama does **not** support speculative decoding as of 2026-07-04. Issue #5800 (opened July 2024) remains open requesting `--model-draft` support matching `llama.cpp`. Feature is not implemented. |

**Implication:** Only `lms` and `mlx_lm.server` can be used for speculative decoding in this repo. `lms` 
support requires UI interaction (incompatible with automated bench harness); `mlx_lm.server` is the viable 
automation target for quantitative benchmarking.

## Decision

> **Deferred 2026-07-04 — pick up here.** Runtime inventory is done (see findings above): of the repo's three runtimes, only `mlx_lm.server` can be automated for speculative decoding (`draft_model` + `num_draft_tokens`); LM Studio is UI-only, Ollama doesn't support it (issue #5800). **Next step when resumed:** benchmark `qwen3-coder:30b` + a same-family drafter (`qwen2.5-coder:1.5b`) on `mlx_lm.server` — tokens/sec, acceptance rate, peak memory — and watch the documented MoE regression risk when draft size nears the active-param count.

Do **not** wire this into any script yet. Revisit as a benchmark task once runtime
support is confirmed. Output of the investigation → model card guidance +
`docs/HARDWARE-RECOMMENDATIONS.md` note, gated by tier.
