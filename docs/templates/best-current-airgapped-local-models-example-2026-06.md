# Self-hosted, air-gapped open-source coding agents that work with Ollama / LM Studio — June 2026

thorough research

## Scope

This comparison is for:

- self-hosted coding agents
- air-gapped or air-gap-friendly deployments
- no SaaS dependency at runtime
- no cloud-only models
- local/open-weight model backends
- Ollama, LM Studio, llama.cpp, vLLM, SGLang, MLX, or OpenAI-compatible local servers

Out of scope:

- GPT / Claude / Gemini / hosted API models
- cloud-only inference
- tools that require sending source code to a third-party service
- commercial SaaS-only coding agents

---

# Short recommendation

| Use case | Recommended stack |
|---|---|
| Best general terminal agent | OpenCode + Qwen3.6-35B-A3B or Qwen3-Coder |
| Best hackable terminal agent | Pi + Qwen3-Coder or Qwen3.6 |
| Best Git-based repo editing | Aider + Qwen3-Coder / Qwen2.5-Coder / DeepSeek-V2.5 |
| Best autonomous SWE sandbox | OpenHands + Qwen3.6-35B-A3B |
| Best VS Code autonomous agent | Cline + Qwen3-Coder or Qwen3.6 |
| Best IDE assistant/autocomplete | Continue + Codestral / Qwen-Coder |
| Best CLI with Ollama profile | Codex CLI OSS mode + gpt-oss / Qwen-Coder |

---

# Agent comparison

| Agent | Type | Open source | Air-gapped fit | Ollama | LM Studio | llama.cpp | vLLM | SGLang | Notes |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| OpenCode | terminal agent | ✅ | ✅ | ✅ | ✅ | ✅ via compatible API | ✅ | ✅ | Strong general local agent; model quality and tool calling matter a lot |
| Pi / pi.dev | terminal coding harness | ✅ | ✅ | ✅ | ✅ | ✅ via compatible API | ✅ | ✅ | Highly extensible; runtime-agnostic via `models.json` |
| Aider | Git editing agent | ✅ | ✅ | ✅ | ✅ via OpenAI-compatible API | ✅ | ✅ |  | Very strong patch/edit workflow |
| OpenHands | autonomous SWE environment | ✅ | ✅ | ✅ | ✅ |  | ✅ | ✅ | Heavier; best when model has long context and strong tool use |
| Codex CLI OSS mode | CLI coding agent | ✅ | ✅ | ✅ | ✅ via compatible API | ✅ via compatible API | ✅ |  | Needs large context; Ollama docs recommend at least 64k |
| Cline | VS Code autonomous agent | ✅ | ✅ | ✅ | ✅ | ✅ via compatible API | ✅ via compatible API |  | Local docs recommend Ollama or LM Studio; compact prompt helps |
| Continue | IDE assistant | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |  | Best for IDE chat/autocomplete rather than full autonomy |

---

# Model families to consider

Only local/open-weight or locally runnable models are listed here.

| Model family | Best use | Strengths | Weaknesses | Notes |
|---|---|---|---|---|
| Qwen3.6-35B-A3B | agentic coding | strong tool use, long context, agent workflows | may need careful quant/runtime setup | OpenHands explicitly recommends it as first local model to try |
| Qwen3-Coder | general coding agent | strong code generation, repo tasks, tool use | larger variants need serious hardware | Probably safest default for local coding agents |
| Qwen2.5-Coder | smaller local coding | mature, efficient, widely supported | weaker than newer Qwen3/Qwen3.6 on complex agent tasks | Good for Aider, Continue, Cline |
| DeepSeek-V2.5 | code editing benchmark strength | strong Aider benchmark result | large; tool behavior depends on runtime/prompting | Good candidate for Aider-style editing |
| Codestral / Codestral-style models | autocomplete / FIM | strong fill-in-middle completion | licensing/version must be checked for enterprise use | Best fit for Continue autocomplete |
| gpt-oss models | Codex CLI / local OSS workflows | designed for local OpenAI tooling | model-specific quality varies | Ollama documents Codex CLI support with gpt-oss models |
| Gemma code-capable variants | lightweight coding/chat | fast, efficient | generally weaker for deep repo edits | Useful on constrained hardware |
| Mistral / Devstral variants | agentic coding | good latency and tool use when available locally | license/runtime details must be checked | Good candidate for OpenCode/Pi/Cline |

---

# Best model by agent

Blank means I do not have enough solid evidence to fill it confidently.

| Agent | Best evidenced local model | Other good candidates | Runtime preference | Important limitations |
|---|---|---|---|---|
| OpenCode | Qwen3-Coder / Qwen3.6 | Devstral, Mistral, Gemma, gpt-oss | Ollama or any OpenAI-compatible local server | Needs models that are good at both code and tool calling |
| Pi | Qwen3-Coder / Qwen3.6 | Gemma, Mistral, gpt-oss | Any OpenAI-compatible runtime | Provider/model config may need compatibility overrides |
| Aider | DeepSeek-V2.5, Qwen3, Qwen2.5-Coder | Qwen3-Coder | Ollama or OpenAI-compatible local server | Weak models may generate code but fail Aider’s edit format |
| OpenHands | Qwen3.6-35B-A3B | Qwen3-Coder | LM Studio, Ollama, vLLM, SGLang | Local LLMs may have limited functionality; needs GPU and long context |
| Codex CLI OSS | gpt-oss via Ollama | Qwen-Coder, Qwen3.6 | Ollama | Requires large context; Ollama recommends at least 64k |
| Cline | Qwen3-Coder / Qwen3.6 | Qwen2.5-Coder, Mistral, Gemma | Ollama or LM Studio | Long prompts can exceed smaller contexts; compact prompt recommended |
| Continue | Codestral-style FIM, Qwen-Coder | Qwen2.5-Coder, Qwen3-Coder | Ollama or LM Studio | Better as IDE assistant/autocomplete than autonomous agent |

---

# Runtime preference matrix

| Runtime | Best for | Weaknesses | Air-gapped notes |
|---|---|---|---|
| Ollama | CLI-first local serving, simple setup, agents | context length often needs explicit tuning | Very good for air-gapped once models are imported |
| LM Studio | GUI model testing, local OpenAI-compatible server | less automation-friendly than Ollama/vLLM | Good for workstation air-gapped use |
| llama.cpp | GGUF, low-level tuning, CPU/GPU flexibility | more manual setup | Excellent for strict offline deployments |
| vLLM | shared GPU servers, throughput, batching | heavier infrastructure | Strong for team/internal model serving |
| SGLang | structured generation, agentic serving | less beginner-friendly | Good for advanced internal deployments |
| MLX / oMLX | Apple Silicon speed | Mac-specific | Good for Mac-based offline setups |

---

# Agent × runtime limitations

| Agent | Ollama notes | LM Studio notes | vLLM/SGLang notes | Main runtime limitation |
|---|---|---|---|---|
| OpenCode | Works well via local API | Works via OpenAI-compatible API | Works via compatible API | Model list/config must match provider model IDs |
| Pi | Supported through `models.json` | Supported through `models.json` | Supported through `models.json` | May need compatibility flags for unsupported API parameters |
| Aider | Native documented path | Works through OpenAI-compatible API | Works through OpenAI-compatible API | Model must reliably produce edit blocks |
| OpenHands | Supported | Documented local setup path | Supported | Needs capable local model, GPU, long context |
| Codex CLI | Official Ollama integration | Possible through compatible local API | Possible through compatible local API | Needs large context, preferably 64k+ |
| Cline | Official local option | Official local option | Possible via compatible API | Long system prompt can break small-context models |
| Continue | Strong documented path | Common local setup | Possible | Autocomplete benefits from specialized FIM models |

---

# Performance evaluation

Fields are intentionally left blank where I do not have reliable evidence.

## Agent-level performance

| Agent | Accuracy | Speed | Tool calling | Repo navigation | Multi-file edits | Autocomplete | Memory efficiency | Evidence confidence |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| OpenCode | High | Medium–High | High | High | High |  | Medium | Medium |
| Pi |  | High | Medium–High | Medium–High | Medium–High |  | High | Low–Medium |
| Aider | High | High | Medium | Medium | High |  | High | High |
| OpenHands | High | Low–Medium | High | High | High |  | Low–Medium | Medium |
| Codex CLI OSS |  | Medium–High | Medium–High | Medium | Medium |  | Medium | Medium |
| Cline | Medium–High | Medium | High | Medium–High | Medium–High |  | Medium | Medium |
| Continue | Medium | High | Low–Medium | Medium | Medium | High | High | High |

---

## Model-level performance for coding agents

| Model family | Coding accuracy | Agent/tool accuracy | Speed | Context handling | Hardware efficiency | Best agents |
|---|---:|---:|---:|---:|---:|---|
| Qwen3.6-35B-A3B | High | High | Medium | High | Medium–High | OpenHands, OpenCode, Pi, Cline |
| Qwen3-Coder | High | High | Medium | High | Medium | OpenCode, Pi, Aider, Cline, Continue |
| Qwen2.5-Coder | Medium–High | Medium | High | Medium | High | Aider, Continue, Cline |
| DeepSeek-V2.5 | High | Medium | Medium | Medium | Medium | Aider |
| Codestral-style FIM | Medium–High |  | High | Medium | Medium–High | Continue |
| gpt-oss |  | Medium–High | Medium–High | High | Medium | Codex CLI, OpenCode |
| Gemma variants | Medium | Medium | High | Medium | High | Continue, Pi, Cline |
| Mistral / Devstral variants | Medium–High | Medium–High | High | Medium–High | High | OpenCode, Pi, Cline |

---

# Practical hardware tiers

| Hardware | Model class | Recommended use |
|---|---|---|
| 8–12 GB VRAM | 7B–14B quantized | Continue, Aider on smaller repos, Cline small tasks |
| 16 GB VRAM | 14B–22B quantized | Qwen2.5-Coder, Codestral-style autocomplete, smaller Qwen-Coder |
| 24 GB VRAM | 30B–35B quantized / MoE | Qwen3-Coder, Qwen3.6-35B-A3B, serious local agentic coding |
| 48–64 GB VRAM | larger quantized models | OpenHands, OpenCode, heavier repo tasks |
| 96 GB+ VRAM | large MoE / multi-user serving | vLLM/SGLang shared internal inference |

---

# Best setups by need

## Need: fully air-gapped, easiest to operate

Use:

- Ollama
- OpenCode or Aider
- Qwen3-Coder or Qwen2.5-Coder
- local Git repository
- no external MCP servers

Best fit:

```text
Ollama + Aider + Qwen-Coder
```

---

## Need: best autonomous coding agent

Use:

- OpenHands
- Qwen3.6-35B-A3B
- LM Studio, Ollama, vLLM, or SGLang
- isolated container/sandbox

Best fit:

```text
OpenHands + Qwen3.6-35B-A3B
```

---

## Need: fast terminal agent

Use:

- OpenCode or Pi
- Ollama
- Qwen3-Coder / Qwen3.6 / Mistral-style model

Best fit:

```text
OpenCode or Pi + Ollama + Qwen3-Coder
```

---

## Need: Git patch accuracy

Use:

- Aider
- Qwen-Coder or DeepSeek-V2.5
- repository with tests

Best fit:

```text
Aider + Qwen-Coder
```

---

## Need: VS Code autonomous workflow

Use:

- Cline
- Ollama or LM Studio
- compact prompt enabled
- long context model

Best fit:

```text
Cline + Ollama + Qwen3-Coder
```

---

## Need: IDE autocomplete and local chat

Use:

- Continue
- Ollama or LM Studio
- Codestral-style FIM model for autocomplete
- Qwen-Coder for chat/edit

Best fit:

```text
Continue + Ollama + Codestral/Qwen-Coder
```

---

# Final ranked shortlist

| Rank | Stack | Why |
|---:|---|---|
| 1 | OpenCode + Qwen3-Coder/Qwen3.6 + Ollama | Best general local terminal agent |
| 2 | Aider + Qwen-Coder + Ollama | Best reliable Git editing workflow |
| 3 | OpenHands + Qwen3.6 + LM Studio/Ollama/vLLM | Best autonomous SWE environment |
| 4 | Pi + Qwen-Coder + local OpenAI-compatible runtime | Most hackable/extensible |
| 5 | Cline + Qwen-Coder + Ollama/LM Studio | Best VS Code autonomous option |
| 6 | Continue + Codestral/Qwen-Coder + Ollama | Best local IDE assistant/autocomplete |
| 7 | Codex CLI OSS + Ollama | Good CLI option, but context and model choice matter |

---

# Notes for air-gapped deployment

Before moving into the air-gapped environment, mirror or export:

- agent source packages
- runtime installers
- model weights
- tokenizer files
- model metadata
- Python/npm dependencies
- VS Code extensions if needed
- documentation snapshots
- licenses
- checksums

For enterprise use, verify each model license separately. “Runs locally” does not always mean “OSI open-source” or “commercially unrestricted.”
