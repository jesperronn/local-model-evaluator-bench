# Question

**Self-hosted, air-gapped open-source coding agents that work with Ollama/LM Studio (June 2026)**

For a **fully self-hosted, air-gapped** coding setup in June 2026, the ecosystem has matured significantly. Most modern coding agents now support **OpenAI-compatible local endpoints**, allowing them to work with **Ollama**, **LM Studio**, **llama.cpp**, **vLLM**, or **SGLang** without requiring Internet access once installed.

## Best open-source coding agents

| Agent | Open Source | Air-gapped | Ollama | LM Studio | Autonomous | Notes |
|-------|-------------|------------|---------|-----------|------------|------|
| **OpenCode** | ✅ MIT | ✅ | ✅ | ✅ | ⭐⭐⭐⭐⭐ | Probably the strongest all-around local coding agent |
| **Pi (pi.dev)** | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐⭐ | Lightweight terminal coding harness; highly extensible with packages, skills, themes, and TypeScript extensions |
| **Aider** | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐⭐ | Excellent for Git-based development |
| **OpenHands** | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐⭐⭐ | Full software engineering agent |
| **Codex CLI** | ✅ Apache-2 | ✅ | ✅ | ✅ | ⭐⭐⭐⭐ | Works with any OpenAI-compatible endpoint |
| **Continue.dev** | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐ | IDE-centric assistant rather than autonomous agent |
| **Cline** | ✅ | ✅ | ✅ | ✅ | ⭐⭐⭐⭐ | VS Code agent with tool use |

---

# 1. OpenCode ⭐ Recommended

GitHub's fastest-growing open-source coding agent.

## Pros

- Excellent terminal UX
- Autonomous planning
- Tool calling
- Git integration
- Local-first design
- Very active development

## Works with

- Ollama
- LM Studio
- llama.cpp
- vLLM
- SGLang

## Example

```bash
opencode \
  --base-url http://localhost:11434/v1 \
  --model qwen3-coder:30b
```

Ideal if you want something comparable to Claude Code but completely local.

---

# 2. Pi (pi.dev)

Pi is a modern **terminal coding harness** designed around extensibility and local-first development.

## Highlights

- Lightweight CLI
- Package ecosystem
- Custom skills
- Themes
- TypeScript extension API
- Model-agnostic
- Local-first architecture

## Works with

- Ollama
- LM Studio
- OpenAI-compatible APIs
- vLLM
- llama.cpp

Pi is an excellent choice if you want something that is:
- Smaller than OpenHands
- More extensible than Aider
- Easier to customize than Codex CLI

---

# 3. Aider

Still arguably the best agent for repository editing.

## Strengths

- Understands Git extremely well
- Iterative editing
- Multi-file refactors
- Automated commits
- Pair programming workflow

## Supports

- Ollama
- LM Studio
- OpenAI-compatible APIs

## Example

```bash
aider \
  --model ollama/qwen3-coder:30b
```

Very stable and proven.

---

# 4. OpenHands

Previously known as **OpenDevin**.

Instead of acting like autocomplete, it behaves like a junior software engineer.

## Can

- Inspect repositories
- Run tests
- Execute shell commands
- Fix build failures
- Browse documentation
- Write pull requests

Runs completely locally when pointed at Ollama or LM Studio.

---

# 5. Codex CLI

OpenAI open-sourced the CLI, and it supports replacing the backend with any OpenAI-compatible local server.

## Example

```bash
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=dummy

codex
```

This allows Codex CLI to work entirely offline with a local inference server.

---

# 6. Continue.dev

Best IDE integration.

## Works in

- VS Code
- JetBrains IDEs

## Connects to

- Ollama
- LM Studio
- llama.cpp
- OpenAI-compatible APIs

Excellent if you prefer an IDE-native experience over a terminal agent.

---

# 7. Cline

A VS Code autonomous coding agent.

## Supports

- Terminal execution
- Filesystem tools
- Browser automation
- MCP servers
- OpenAI-compatible APIs

Very popular for local development with Ollama.

---

# Recommended local models

## <16 GB VRAM

- Qwen3-Coder 14B
- DeepSeek Coder V3 Lite
- Devstral Small

---

## 24 GB VRAM ⭐ Sweet spot

- Qwen3-Coder 30B
- Devstral Medium
- DeepSeek V4

---

## 48–96 GB+

- Qwen3-Coder 235B (quantized)
- Kimi K2.x
- DeepSeek V4 (full)

These larger models narrow the gap to the best cloud-hosted coding models for many software engineering tasks.

---

# Ollama vs LM Studio

| Feature | Ollama | LM Studio |
|---------|---------|-----------|
| CLI | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| API server | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| GUI | ❌ | ⭐⭐⭐⭐⭐ |
| Docker | ⭐⭐⭐⭐⭐ | ⭐ |
| Air-gapped | ✅ | ✅ |
| Automation | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

For servers and CI, Ollama is generally the better choice. For experimenting interactively, LM Studio provides a polished GUI. Both expose OpenAI-compatible APIs that these agents can consume.

---

# Recommended stacks

## Minimal workstation

- Ollama
- OpenCode
- Qwen3-Coder 30B

---

## Professional developer

- Ollama
- Pi
- OpenHands
- Aider
- Continue.dev
- Qwen3-Coder 30B or DeepSeek V4

---

## High-security / air-gapped enterprise

- Ollama or llama.cpp
- OpenCode or Pi
- OpenHands for autonomous engineering tasks
- Local GitLab or Gitea
- Self-hosted MCP servers hosted entirely on the internal network

All of these components can operate without Internet connectivity once the software, models, and dependencies have been transferred into the air-gapped environment.