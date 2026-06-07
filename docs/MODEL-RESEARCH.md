# Model research — candidates & sources

Related: [README](../README.md) · [docs/SETUP.md](SETUP.md) (which model / which quant)
· [BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md)

Running log of local-model candidates worth benchmarking, with sources. Append
new findings with a dated heading; don't rewrite old entries (so we can see how
the landscape moved). Selection criteria live in
[README §design-criteria #4](../README.md) — prefer MLX / MoE-A3B / QAT / MTP.

---

## 2026-06 — modern-feature sweep (≈last 60 days)

Machine: Apple M5 Max, 128 GB — fit is not the constraint up to ~90 GB resident,
so quant is an accuracy/speed choice (see [SETUP.md](SETUP.md)).

### Candidates we don't yet run

| Model | Arch | Active | Why consider | Footprint (≈4-bit) |
|-------|------|--------|--------------|--------------------|
| **Qwen3-Coder-Next** | MoE 80B, hybrid attn | 3B (10/512 experts) | Best match to our criteria: A3B + native MTP + MLX, coding-specialized; "Sonnet 4.5-level" claim | 44.86 GB (MLX 4-bit); **6-bit 64.76 GB picked** |
| **Qwen3.6-27B** (dense) | Dense | 27B | Top local-coder accuracy (77.2 SWE-bench Verified > 73.4 for 35B-A3B); dense → biggest MTP gain (1.4–2×) | ~16–18 GB |
| **MiniMax M3** | MoE | ? | Newest (Jun 2026); tops open-weight SWE-Bench Pro (59.0). Verify footprint before pulling | likely large |
| **Kimi K2.6** | MoE 1T | 32B | Strongest open-weight overall (AA Index 54), native INT4 QAT — but homelab-scale | too big |
| **DeepSeek V4-Flash** | MoE 284B | 13B | MIT, 1M context, FP4/FP8; self-host-friendly variant | big |
| **GLM-5.1** | MoE | ? | Competitive open weight (AA 51); no clear small/MLX build surfaced | ? |

### Already in our lineup (for reference)
`qwen3.6-35b-a3b` (MoE/A3B), `gemma-4-26b-a4b-qat` (MoE+QAT), `gemma-4-12b-qat`,
`qwen3-coder-30b`, plus dense Gemma-4 / small Qwen.

### Free speedup, no new model
Enable **MTP** on the Qwen3.6 models we already run — MTP-converted GGUFs are
downloadable in LM Studio (merged into llama.cpp PR #22673, 2026-05-16),
~1.4–2× generation, no accuracy loss.

### Sources
- Qwen3-Coder-Next: [blog](https://qwen.ai/blog?id=qwen3-coder-next) · [HF](https://huggingface.co/Qwen/Qwen3-Coder-Next) · [DEV guide](https://dev.to/sienna/qwen3-coder-next-the-complete-2026-guide-to-running-powerful-ai-coding-agents-locally-1k95) · [Ollama](https://ollama.com/library/qwen3-coder-next) · [LM Studio](https://lmstudio.ai/models/qwen3-coder-next)
- Qwen3.6 family: [Unsloth docs](https://unsloth.ai/docs/models/qwen3.6) · [HF 27B](https://huggingface.co/Qwen/Qwen3.6-27B) · [complete guide](https://thinksmart.life/research/posts/qwen-3.6-complete-guide-agentic-coding-local-inference/)
- Best local coding models 2026: [InsiderLLM coding](https://insiderllm.com/guides/best-local-coding-models-2026/) · [InsiderLLM Mac](https://insiderllm.com/guides/best-local-llms-mac-2026/) · [Kilo open-source](https://kilo.ai/open-source-models) · [Kilo leaderboard](https://kilo.ai/leaderboard)
- Chinese-lab releases (GLM-5.1 / MiniMax / Kimi K2.6 / DeepSeek V4): [Medium — what's real](https://medium.com/@candemir13/three-weeks-four-chinese-coding-models-whats-actually-real-and-what-s-overstated-4cb58199e83d) · [Kimi vs DeepSeek vs GLM](https://codersera.com/blog/kimi-k2-6-vs-deepseek-v4-vs-glm-5-1-2026/) · [The Batch — Kimi K2.6](https://www.deeplearning.ai/the-batch/kimi-k2-6-matches-open-qwen3-6-max-anddeepseek-v4-falls-just-behind-top-closed-models) · [BenchLM Chinese LLMs](https://benchlm.ai/blog/posts/best-chinese-llm) · [AkitaOnRails benchmark](https://akitaonrails.com/en/2026/04/24/llm-benchmarks-parte-3-deepseek-kimi-mimo/)
- MTP / speculative decoding: [MTP in LM Studio](https://localllm.in/blog/mtp-lm-studio) · [llama.cpp MTP gist](https://gist.github.com/eeshansrivastava89/85797104af34181944bfd1360d69e8af) · [Dre Dyson step-by-step](https://dredyson.com/mtp-llama-cpp-with-qwen3-6-27b-a-complete-beginners-step-by-step-guide-to-speculative-decoding-turboquant-and-running-multiple-models-on-limited-gpu-vram/)
- Small models (32 GB tier): [Best small LMs 2026](https://localaimaster.com/blog/small-language-models-guide-2026) · [InsiderLLM Mac](https://insiderllm.com/guides/best-local-llms-mac-2026/) · [HF open-source LLMs](https://huggingface.co/blog/daya-shankar/open-source-llms) · [Ollama cheat sheet](https://computingforgeeks.com/ollama-models-cheat-sheet/)
- MLX on Apple Silicon: [codersera MLX guide](https://codersera.com/blog/apple-silicon-llms-complete-guide-2026/) · [mlx-optiq models](https://mlx-optiq.com/models) · [Rapid-MLX engine](https://github.com/raullenchai/Rapid-MLX) · [Ollama 0.19 MLX backend](https://medium.com/@tentenco/ollama-0-19-ships-mlx-backend-for-apple-silicon-local-ai-inference-gets-a-real-speed-bump-878b4928f680) · [Simon Willison MLX tag](https://simonwillison.net/tags/mlx/)

### Small, accurate models for simpler edits (M2 Max 32 GB tier)

For single-file bugfixes, tab-complete, and light refactors where the 80B rig is
overkill. Budget ≤~24 GB on the 32 GB Mac. Prefer MLX.

| Model | Size (≈4-bit) | Features | Why |
|-------|---------------|----------|-----|
| **qwen3.5-9b** | 5.98 GB | dense, MLX | Already our top small baseline — scored 15/15 on 3 of 4 tools. Default for simple edits. |
| **Qwen2.5-Coder-7B / 14B** | ~4.5 / ~9 GB | dense, **FIM**, MLX | Tab-complete / fill-in-middle champion; HumanEval 88.4 (7B) / 89 (14B). Best for autocomplete + tiny edits. |
| **Qwen3-8B** | ~5 GB | dense, MLX | Highest HumanEval (76.0) under 8B; good general small coder. |
| **gemma-4-12b-qat** | 7.15 GB | dense, **QAT** | Already in lineup; QAT → strong at low bit-width. |
| **Qwen3.6-27B** | ~17 GB | dense, MTP, MLX | Accuracy ceiling that still fits 32 GB (~25.6 tok/s Q4). Use when a "simple" edit needs flagship correctness. |

Note: `qwen3.6-35b-a3b` (~20 GB, A3B) also fits 32 GB and runs fast (3B active) —
good middle option when an edit spans a couple files.

### Search queries used (to re-run later)
- `best local LLM MLX MoE A3B 2026 coding model release`
- `new open weight MoE coding model April May 2026 MLX quantization`
- `Qwen3 Coder MoE A3B multi-token prediction MTP local LM Studio 2026`
- `Kimi K2.6 GLM-5 MiniMax DeepSeek open weight coding model May June 2026 local MLX`
- `new small MoE A3B coding model 2026 QAT MLX fits 32GB mac fast tokens`
- `Qwen3-Coder-Next MoE A3B size active params MTP MLX 2026 release`
