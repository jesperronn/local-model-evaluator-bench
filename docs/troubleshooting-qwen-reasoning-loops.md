# Surviving the Qwen 3.6 Reasoning Loops (June 2026 Guide)

Advanced reasoning models (like **qwen/qwen3.6-35b-a3b** and **qwen/qwen3-coder-30b**,
alongside DeepSeek-R1 and QwQ) utilize deep Chain-of-Thought (CoT) logic via embedded
`<think>` tokens. While highly capable, they can occasionally suffer from
**attention reinforcement trap**, getting caught in infinite thinking loops where they
repeat the same realizations, doubts, or debugging steps over and over.

> **Model name note:** This suite documents "qwen3.6-30b-a3b" colloquially, but the
> actual model is **qwen/qwen3.6-35b-a3b** (35B total parameters, 3B active MoE).
> There is also **qwen/qwen3-coder-30b** (dense 30B, code-specialized) — see
> [docs/models/](models/) for both. Both exhibit the reasoning loop problem when
> reasoning is enabled.

---

## 🔍 Examples to Watch For

### 1. The Conceptual Existential Crisis (Debugging Loop)
The model gets stuck on a specific programmatic contradiction and endlessly re-evaluates it without moving forward.
> **Thinking Block Example:**
> "integrate: attempt 1/5 for HEAD → main
> Current branch wt1 is up to date.
> If it's always 1/5, then attempt is always 1.
> Maybe attempt=$((attempt + 1)) is failing? But set -e is on.
> Wait, if attempt was incremented...
> Wait! Look at the output again.
> How can attempt be always 1?
> Wait, if attempt was incremented, it would be attempt 2/5..." *(Repeated indefinitely)*

### 2. The Token Hesitation Trap
The self-attention mechanism weights transitional words so heavily that it forgets to reach a conclusion.
> **Thinking Block Example:**
> "Let me think through the design carefully before asking....
> The tricky part is...
> I'm considering a few approaches...
> Actually, I think a simpler approach works better...
> wait... 
> Let me think through the design carefully before asking...." *(Repeated indefinitely)*

---

## 🛠️ Proven Workarounds

### 1. Wipe the Slate Clean (Context Poisoning Fix)
Once a model loops, the conversational history is permanently biased toward looping. Asking it to "stop looping" rarely works.
* **Action:** Open a brand-new chat session. Copy only your core code/error and explicitly state: *"Starting fresh. The previous session got stuck analyzing line X. Let’s bypass that and look directly at how variables are scoped between the subshell and the parent environment."*

### 2. Sharpen Your Hyperparameters (API / Local Runners)
If running Qwen 3.6 locally via Ollama, LM Studio, or via an API, tweak your inference settings to kick the model out of deterministic loops:
* **Temperature:** Lock it between `0.6` and `0.7`. Avoid `0` (which causes rigid, repetitive loops) and avoid going past `1.0` (which breaks reasoning tags).
* **Penalties:** Introduce a mild `presence_penalty` and `frequency_penalty` (set both between `0.1` and `0.3`) to penalize the model for re-using the exact same tokens like *"Wait..."* or *"Actually..."*.

### 3. Loop-Blocking Prompt Architecture
Pre-empt the loop by defining rigid boundaries inside your prompt if you are dealing with complex code (e.g., nested Bash subshells or recursive functions).
* **Example Directive:** > *"Analyze the following script. Do not get stuck in an investigative loop. If your first hypothesis regarding the counter variable fails, do not re-verify it; immediately pivot your attention to the environmental layer (e.g., subshell variable bleeding)."*

---

## 🔧 Implementation: Control Reasoning in This Suite

### How thinking-level is configured per runtime

**In this benchmark suite** (see [adapters/](../adapters/)):

| Runtime | Method | Current Default | Reference |
|---------|--------|-----------------|-----------|
| **pi (MLX/Ollama)** | `--thinking off` flag | Off | [adapters/pi-mlx.sh](../adapters/pi-mlx.sh) line 23, [adapters/caveman-ollama.sh](../adapters/caveman-ollama.sh) line 15 |
| **caveman (Ollama)** | `--thinking off` flag | Off | [adapters/caveman-ollama.sh](../adapters/caveman-ollama.sh) line 15 |
| **Continue/cn (LMS)** | `--silent` flag | Strips `<think>` tags | [adapters/cn-lms.sh](../adapters/cn-lms.sh) line 50 |
| **Cline (LMS/VS Code)** | `/no_think` prompt suffix | Off (manually via GUI) | [docs/extensions/cline.md](extensions/cline.md#recommended-connection-settings) |
| **llama.cpp (any runtime)** | `--chat-template-kwargs '{"preserve_thinking": false}' --jinja` | False | [docs/MODEL-RESEARCH.md](MODEL-RESEARCH.md) line 128 |

### Recommended settings if enabling reasoning

If you intentionally want reasoning enabled for exploratory or research tasks, apply
these **hyperparameter adjustments** to mitigate loops:

```bash
# Add to config.sh or pass via agent config apply:
export ADAPTER_DEFAULT_TEMPERATURE="0.65"           # 0.6–0.7 (not 0)
export ADAPTER_DEFAULT_PRESENCE_PENALTY="0.15"      # 0.1–0.3
export ADAPTER_DEFAULT_FREQUENCY_PENALTY="0.15"     # 0.1–0.3
```

Apply these **before** enabling reasoning:
1. Disable in adapter: remove `--thinking off` from pi/caveman, or remove `--silent` from cn
2. Add hyperparameters via `bin/suggest-tuning` or direct `llmrun agents config apply`
3. Test on 2–3 non-critical cases before full runs

### Detecting the loop (warning signs)

Check logs for repeated patterns like:
- `"Wait, if X was Y, then..."` repeated 5+ times
- Same line-number hypothesis re-evaluated in successive `<think>` blocks
- Token count in `<think>` exceeding 40–50% of total output tokens on simple edits

If detected, disable reasoning and re-run with fresh context (new chat session).

### What NOT to do

- ❌ Do not try to "fix" a looping model mid-conversation — the context is poisoned
- ❌ Do not set `temperature=0` with reasoning enabled — locks the model into deterministic loops
- ❌ Do not increase `max_tokens` to "let it think longer" — provides more rope for looping
- ❌ Do not run reasoning against code with explicit contradictions or unsolved issues in the prompt (e.g., "this variable is both 1 and 2")

---

## Further Reading

- **Benchmark results:** [docs/models/qwen--qwen3.6-35b-a3b.md](models/qwen--qwen3.6-35b-a3b.md) · [docs/models/qwen--qwen3-coder-30b.md](models/qwen--qwen3-coder-30b.md) (includes "Thinking level / reasoning" sections with model-specific guidance)
- **General reasoning configuration:** [docs/extensions/cline.md § Recommended connection settings](extensions/cline.md#recommended-connection-settings)
- **llama.cpp reasoning flags:** [docs/MODEL-RESEARCH.md § Inference config notes](MODEL-RESEARCH.md#inference-config-notes-llamacpp)
```
