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

---

## 2026-06-30 — Community thread: "Best local agents Jun 2026" (r/LocalLLaMA)

Source: https://www.reddit.com/r/LocalLLaMA/comments/1uaebfe/best_local_agents_jun_2026/

A megathread with 50+ practitioners sharing real-world setups. Highlights below
are selected for relevance to this benchmark project.

### Agents / harnesses mentioned

| Name | Notes |
|------|-------|
| **Nanocoder** | CLI, local-first by default. Ollama / LM Studio / llama.cpp / MLX all work out of box. MIT. Plan mode + subagents + VS Code diff extension. Described as "the test is whether it holds up on real codebases with local models." **Strongest new adapter candidate.** |
| **oh-my-openagent** | Agentified fork of OpenCode (`code-yeongyu/oh-my-openagent`). Praised for workflow planning mode and coding/debugging flows. One strong endorsement over Pi and OpenCode. |
| **mi** | 30-LOC core agentic loop; fits in model context window. Multi-turn REPL. Skills/tools loaded as plugins. Interesting for testing if small models can reason about their own harness. |
| **OpenCode** | Confirmed "bulky for local models" by multiple independent users. Recommended for 122B+ due to long-context capacity. Has web UI (`opencode web`). |
| **Pi** | Most conventional/popular full-featured harness. Good for hands-on interactive use. Custom llama-server config requires manual setup. |
| **Hermes** | Only agent with a smooth custom OpenAI-compatible endpoint onboarding flow (no manual config file editing). Used with Qwen3.6-35B + Gemma4 31B. |
| **OpenClaw / Hermes-agent** | Explicitly called "badly designed" in thread. |
| **Agent2077** | WebUI-based. Self-development mode: model edits its own source in a sandboxed copy, runs build test, spins up dev instance for user approval before promotion to prod. |
| **localcode** | Custom agent by `Trooper3001` for Qwen3.6-27B. In a Pac-Man clone test, outperformed OpenCode and Pi (both produced frozen games; localcode produced a working game with a ghost movement bug). Repo: `Trooper3001/localcode`. |
| **GuideAnts** | Proxy/orchestration layer that publishes guides as Claude Code / Codex wire-compatible endpoints, routing inference to any local model. Different architecture from typical agents. |

### Model quality signals from real-world agentic use

- **Qwen3.6-35B-A3B** — dominant daily driver across thread. Q6_K_XL or UD-IQ4_NL_XL
  are common quant sweet spots. MoE offloading to RAM works well; llama.cpp `--fit`
  handles layer placement automatically.
- **Qwen3.6-27B** — second most common. Opencode's preferred pairing.
- **DeepSeek V4 Flash** — one user rates quality clearly above Qwen3.6: *"really in a
  higher league."* Requires large hardware (GB10 or 2×DGX Sparks). Self-host viable.
- **Gemma4 26B / 31B** — two independent users report poor instruction-following in
  agentic loops: *"talks the talk and secretly acts like Forest Gump."* Both switched
  to Qwen3.6 on recommendation. Corroborates potential bench findings.
- **Qwen3-Coder 30B A3B** — reliable for scoped tasks with a verification gate; not
  Sonnet-level on large multi-file changes.

### Tool call failures — directly relevant to bench design

- One Opencode + Qwen 27B user estimates **~30% of tool call failures are unnecessary**:
  parameters are valid but formatting differs slightly from what the harness expects.
- Root cause: two distinct failure modes conflated:
  1. Chat template parser rejects malformed LLM output before the agent sees it
  2. Agent rejects structurally valid call with wrong parameter names/shape
- Proposed fix: fuzzy matching at the chat template layer, or bypassing template
  parsing so the agent handles both steps together. No implementation exists yet.
- This validates the cline adapter normalization approach in this project (ca00f15).
- **Tool call leaking after a few agentic loops** reported on `Qwen3.6-35B-A3B-heretic`
  variant specifically (DeepSeek-heretic quantization). No fix given in thread.

### Benchmarking philosophy quotes

> *"passes to clear the gate has become a way better metric for me than any eval
> score"* — typecheck + lint + test + boot probe as the acceptance gate.
> (Mayimbe_999, 5090 / Qwen3-Coder 30B A3B at Q5_K_M ~120 t/s)

> *"I keep ~15 real tasks from my own work and rerun them whenever I swap the model
> or harness, caught way more regressions than any leaderboard ever did."*
> (Hot-Leadership-6431, M4 Max Studio 64 GB / Qwen3.5 32B local sub-agent)

Both affirm a smoke-test / real-task-gate approach over static evals.

### Inference config notes (llama.cpp)

- `--chat-template-kwargs '{"preserve_thinking": true}' --jinja` required for Qwen3
  thinking models — without it, `<think>` tokens leak or get stripped.
- MTP on Apple Silicon is **slower** without the fp16 MTP variant:
  `Jundot/Qwen3.6-27B-oQ4-fp16-mtp` on HuggingFace gives ~80% speedup on M2 Max.
- KV cache: community consensus is `q8_0/q8_0`; `q5_1/q4_0` called out as a quality
  regression (see `--cache-type-k` / `--cache-type-v` flags).
- Context recall drift reported beyond 120k even when model nominally supports more.
- `--n-cpu-moe` flag for MoE CPU offloading; llama.cpp `--fit` auto-tunes if unset.

### Search queries used (to re-run later)
- `best local LLM MLX MoE A3B 2026 coding model release`
- `new open weight MoE coding model April May 2026 MLX quantization`
- `Qwen3 Coder MoE A3B multi-token prediction MTP local LM Studio 2026`
- `Kimi K2.6 GLM-5 MiniMax DeepSeek open weight coding model May June 2026 local MLX`
- `new small MoE A3B coding model 2026 QAT MLX fits 32GB mac fast tokens`
- `Qwen3-Coder-Next MoE A3B size active params MTP MLX 2026 release`

---

### Gemma 4 MTP investigation

**Context:** Google released official MTP assistant drafter models for all Gemma 4 sizes
alongside llama.cpp PR #23398 (b9549, June 7 2026), which added MTP speculative decoding
support. We currently bench `google/gemma-4-e4b` and `google/gemma-4-26b-a4b-qat`.

#### Model IDs (HuggingFace)

| Base model | Drafter (BF16 safetensors) |
|---|---|
| `google/gemma-4-E4B-it` | `google/gemma-4-E4B-it-assistant` (~79M params, 165 MB F16) |
| `google/gemma-4-26B-A4B-it` | `google/gemma-4-26B-A4B-it-assistant` |

Note: the 26B drafter HF ID follows the same pattern. There is no official
`gemma-4-27b-it-assistant` — the 27B dense variant is a separate model family.

#### GGUF availability

Community GGUF builds exist (AtomicChat/gemma-4-E4B-it-assistant-GGUF, Q4_K_M ~75 MB)
but carry a **critical compatibility caveat**: they use a custom `gemma4_assistant`
architecture not present in upstream llama.cpp. Loading them in stock llama.cpp or LM
Studio will fail with "unknown architecture" error. They require the
[atomic-llama-cpp-turboquant](https://github.com/AtomicBot-ai/atomic-llama-cpp-turboquant)
fork. Google's own HF repo ships BF16 safetensors only (no GGUF from Google or ggml-org
at time of writing).

#### LM Studio support status

LM Studio 0.3.10 added speculative decoding support (GUI sidebar + `draft_model` API
parameter). However, **LM Studio does not yet support Gemma 4 MTP drafters** because:

1. The `gemma4_assistant` GGUF architecture requires a patched llama.cpp build not
   bundled with LM Studio.
2. LM Studio's built-in speculative decoding works with same-family GGUF draft models
   (e.g. Llama 3.2 1B drafting for Llama 3.1 8B), not custom MTP head architectures.
3. No mechanism to load a BF16 safetensors drafter alongside a GGUF base model.

The `lms get <url>` CLI path would download the BF16 model but LM Studio cannot pair it
as a drafter for GGUF inference.

#### Apple Silicon performance (M-series)

- M1 Max 64 GB: 58.2 → 69.2 tok/s (+19%) reported for Gemma 4 E4B with MTP drafter
  via llama.cpp directly (not LM Studio). Modest gain, not the 1.4–3× headline.
- The larger headline speedups (1.4–2.2×) are reported on GPU-heavy setups
  (RTX 4070 Super, dual 3090). Apple Silicon is memory-bandwidth-bound, so the
  drafter verification cost eats more of the gain than on discrete GPUs.
- Dense models (Gemma 4 31B) benefit more than MoE variants. Our bench uses the MoE
  26B-A4B, which likely sees even smaller gains.
- The fp16 MTP variant matters on Apple Silicon: Qwen3.6-27B users saw ~80% speedup
  only with a dedicated fp16-MTP GGUF build. Gemma equivalent not yet available.

#### Recommended path if you want to try it

Use **llama-server directly** (not LM Studio), with a llama.cpp build at b9549+:

```sh
llama-server \
  --model gemma-4-E4B-it-Q4_K_M.gguf \
  --mtp-head gemma-4-E4B-it-assistant-Q4_K_M.gguf \
  --host 0.0.0.0 --port 1234
```

This requires the atomic-llama-cpp-turboquant fork for the GGUF drafter, or running the
BF16 safetensors version via HuggingFace Transformers (Python, slower on Apple Silicon).

#### Recommendation: **skip for now**

| Factor | Assessment |
|---|---|
| LM Studio support | Not supported — requires llama.cpp fork |
| Drafter GGUF quality | Fork-only; upstream ggml-org GGUF not available |
| Apple Silicon speedup | ~19% observed (M1 Max); well below 1.4× claim |
| Bench disruption | Would require switching from LM Studio to llama-server for affected models |
| Gemma 4 quality in bench | Already flagged as poor instruction-following in agentic loops (see community thread above) |

The infrastructure cost (leaving LM Studio, adding a fork dependency) is not justified by
a 19% throughput gain on models that already underperform in our bench. Re-evaluate when:
(a) upstream llama.cpp gains native `gemma4_assistant` arch support, or (b) LM Studio
bundles MTP drafter support for Gemma 4 specifically.

**Search queries used:**
- `LM Studio speculative decoding drafter model support 2026`
- `google gemma-4-e4b-it-assistant gemma-4-27b-it-assistant huggingface GGUF drafter`
- `llama.cpp MTP speculative decoding gemma 4 apple silicon speedup 2026`

**Sources:**
- [LM Studio 0.3.10 blog — Speculative Decoding](https://lmstudio.ai/blog/lmstudio-v0.3.10)
- [LM Studio speculative decoding docs](https://lmstudio.ai/docs/app/advanced/speculative-decoding)
- [google/gemma-4-E4B-it-assistant on HuggingFace](https://huggingface.co/google/gemma-4-E4B-it-assistant)
- [AtomicChat/gemma-4-E4B-it-assistant-GGUF on HuggingFace](https://huggingface.co/AtomicChat/gemma-4-E4B-it-assistant-GGUF)
- [AtomicChat/gemma-4-26B-A4B-it-assistant-GGUF on HuggingFace](https://huggingface.co/AtomicChat/gemma-4-26B-A4B-it-assistant-GGUF)
- [llama.cpp PR #23398 — add Gemma4 MTP](https://github.com/ggml-org/llama.cpp/pull/23398)
- [DEV.to — How to Get 2x Speed on Gemma 4 with MTP in llama.cpp](https://dev.to/everylocalai/how-to-get-2x-speed-on-gemma-4-with-multi-token-prediction-in-llamacpp-1b8e)
- [Gemma 4 MTP Local Inference Benchmarks](https://ai.plainenglish.io/i-spent-3-nights-testing-gemma-4-mtp-6711c8589d2f)
