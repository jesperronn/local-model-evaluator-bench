# Local Model Agents Configuration & Testing Guide

## Status Overview

### ✅ Ollama Running
- Base URL: `http://localhost:11434/v1`
- Available models: phi4:latest, gemma4-claude:latest, qwen2.5-coder-7b:latest, etc.

### ⚠️ LM Studio Not Running
- Expected URL: `http://localhost:8000/v1`
- When started, all agents can be configured to use it

---

## Agent Setup Instructions

### 1. Mistral Vibe (vibe)

**Install:** ✅ Already installed via `uv tool install mistral-vibe`

**Setup for Ollama:**
```bash
# First time - interactive setup
vibe --setup

# Or set provider via environment
export VIBE_ACTIVE_MODEL=local
export VIBE_PROVIDERS_OLLAMA_BASE_URL=http://localhost:11434/v1

# Usage
vibe -p "What is 2+2?" --auto-approve
```

**Setup for LM Studio:**
```bash
export VIBE_ACTIVE_MODEL=lm_studio
export VIBE_PROVIDERS_LM_STUDIO_BASE_URL=http://localhost:8000/v1

vibe -p "What is 2+2?" --auto-approve
```

---

### 2. Pi Coding Agent (omp)

**Install:** ✅ Already installed globally

**Setup for Ollama:**
```bash
# Use config file
omp -p "What is 2+2?" --config ~/.omp/config/local-models.toml --auto-approve

# Or specify model directly
omp -p "What is 2+2?" --model ollama/qwen3.5:9b --auto-approve
```

**Setup for LM Studio:**
```bash
# When LM Studio is running and detected
omp -p "What is 2+2?" --model lm-studio/default --auto-approve

# Or list available models
omp models list
```

**Detect Local Models:**
```bash
omp models list  # Shows Ollama and LM Studio models
```

---

### 3. Qwen Code (qwen)

> **Stale as of 2026-08-08:** `QWEN_API_TYPE`/`QWEN_API_BASE` below are not
> real env vars in the current qwen-code (0.21.7) — it reads
> `OPENAI_API_KEY`/`OPENAI_BASE_URL`/`OPENAI_MODEL` (or `QWEN_MODEL` as an
> alias for `OPENAI_MODEL`) instead. See `adapters/qwen-omlx.sh` for the
> current, verified-working setup, and `docs/HANDOFF-phone-home-audit.md` —
> this CLI phones home to Alibaba on 3 paths unless explicitly suppressed.

**Install:** ✅ Already installed globally

**Setup for Ollama:**
```bash
# Set environment variables
export QWEN_API_TYPE=ollama
export QWEN_API_BASE=http://localhost:11434/v1
export QWEN_API_KEY=ollama

# Usage
qwen -p "What is 2+2?"
```

**Setup for LM Studio:**
```bash
export QWEN_API_TYPE=openai
export QWEN_API_BASE=http://localhost:8000/v1
export QWEN_API_KEY=lm-studio

qwen -p "What is 2+2?"
```

**Interactive Mode:**
```bash
# With model selection
qwen -m qwen3.5:9b
```

---

### 4. SHAI

**Install:** ✅ Already installed at `~/.local/bin/shai`

**Setup for Ollama:**
```bash
# Set up local agent (already configured)
shai agent list

# Use the local agent
shai agent local

# Headless mode
echo "What is 2+2?" | shai agent local
```

**Interactive Authentication Setup:**
```bash
shai auth
# Select "Other provider" or custom endpoint
# Enter: http://localhost:11434/v1
# API Key: ollama
```

**Setup for LM Studio:**
```bash
# Create LM Studio agent config
cat > ~/.config/shai/agents/lm-studio.config << 'EOF'
{
  "name": "lm-studio",
  "description": "Local models via LM Studio",
  "tools": {
    "builtin": ["*"]
  },
  "system_prompt": "{{CODER_BASE_PROMPT}}",
  "max_tokens": 8192,
  "temperature": 0.3
}
EOF

# Use it when LM Studio is running
shai agent lm-studio
```

---

## Testing Checklist

### Ollama Tests (Current - Ollama Running ✅)

- [ ] `vibe -p "What is 2+2?" --auto-approve`
- [ ] `omp -p "What is 2+2?" --model ollama/qwen3.5:9b --auto-approve`
- [ ] `qwen -p "What is 2+2?" -m qwen3.5:9b`
- [ ] `echo "What is 2+2?" | shai agent local`

### LM Studio Tests (When Started)

- [ ] Test Mistral Vibe with LM Studio endpoint
- [ ] Test omp with LM Studio models
- [ ] Test Qwen with LM Studio
- [ ] Test SHAI with LM Studio agent

---

## Key Command Differences

| Agent | Run with Prompt | List Models | Set Model |
|-------|-----------------|-------------|-----------|
| **vibe** | `vibe -p "..."` | (auto-detects) | env vars |
| **omp** | `omp -p "..."` | `omp models list` | `--model` flag |
| **qwen** | `qwen -p "..."` | (auto-detects) | `-m` flag |
| **shai** | `echo "..." \| shai` | (auto-detects) | `agent` command |

---

## Troubleshooting

### Mistral Vibe fails
- Clear config: `rm -f ~/.vibe/config.toml`
- Run: `vibe --setup` (interactive)
- Or set env vars directly

### omp doesn't find models
- Check: `omp models list`
- Ensure Ollama/LM Studio are running
- Use specific model with `--model` flag

### Qwen Code needs auth
- Set: `export QWEN_API_TYPE=ollama`
- Set: `export QWEN_API_BASE=http://localhost:11434/v1`
- Run in non-interactive: `qwen -p "..." --output json`

### SHAI returns OVHCloud results
- Run: `shai auth` and select Ollama endpoint
- Or use: `shai agent local` (pre-configured)

---

## Next Steps

1. Test all agents with Ollama (current state)
2. Start LM Studio and test all agents again
3. Document performance/compatibility results
4. Integrate into benchmark framework
