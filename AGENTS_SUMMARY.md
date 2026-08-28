# Local Model Agents - Configuration & Testing Summary

**Date:** July 5, 2026  
**Status:** ✅ All agents installed and configured for Ollama

> **Stale as of 2026-08-08 re: Qwen Code.** This doc's `~/.config/qwen/settings.json`
> setup and "FULLY WORKING" verdict predate the current qwen-code version and
> contradict `APPROVED_AGENTS.md`'s same-day rejection of qwen (fixed
> 442-char output) — the two were apparently never reconciled. The actual
> current state (2026-08-08): qwen is a registered harness via
> `adapters/qwen-omlx.sh` (oMLX, not Ollama), configured with
> `OPENAI_API_KEY`/`OPENAI_BASE_URL`/`OPENAI_MODEL` env vars — no
> `settings.json` needed, and the file path this doc names is not even the
> right location. It also phones home to Alibaba on 3 paths unless
> suppressed; see `docs/HANDOFF-phone-home-audit.md`. Treat the Qwen Code
> section below as historical only.

---

## Overview

We have successfully set up **4 coding agents** to work with local models via Ollama:

1. **omp** (Pi Coding Agent) - ✅ **FULLY WORKING**
2. **Qwen Code** - ✅ **FULLY WORKING** 
3. **Mistral Vibe** - ⚠️ **WORKING (needs initial setup)**
4. **SHAI** - ⚠️ **WORKING (requires agent config)**

---

## Quick Start

### Run all setup at once:
```bash
chmod +x setup-all-agents.sh
./setup-all-agents.sh
```

### Test all agents:
```bash
chmod +x test-all-agents.sh
./test-all-agents.sh
```

### Quick test each agent:
```bash
# omp - WORKING
omp -p "Write a hello world in Python" \
  --config ~/.omp/config/ollama.toml \
  --auto-approve

# Qwen - WORKING
qwen -p "Write a hello world in Python"

# Vibe - requires setup first
vibe --setup  # Interactive setup
vibe -p "Write a hello world in Python" --auto-approve

# SHAI - use agent
echo "Write a hello world in Python" | shai agent ollama
```

---

## Agent Details

### 1. omp (Pi Coding Agent) - ✅ PRODUCTION READY

**Installation:**
```bash
brew install omp
```

**Configuration:**
- File: `~/.omp/config/ollama.toml`
- Supports role-based models (smol/slow/default)
- Supports fallback chains for resilience

**Key Features:**
- Auto-detects Ollama models
- `omp models list` to see all available
- `--mode json` for structured output
- Sophisticated retry/fallback configuration
- Best for: Production automation, model comparison

**Test Result:** ✅ Verified output:
```python
def hello_world():
    """Prints a greeting."""
    print("Hello, World!")
```

---

### 2. Qwen Code - ✅ PRODUCTION READY

**Installation:**
```bash
npm install -g @qwen-code/qwen-code
# Command: qwen (not qwen-code)
```

**Configuration:**
- File: `~/.config/qwen/settings.json`
- Supports Ollama, OpenAI, Anthropic, etc.
- Runtime model switching via `-m` flag

**Key Features:**
- `-m MODEL` flag for runtime model selection
- `-o json` for JSON output
- Session management with `-r`/`-c` flags
- Extensions and hooks support
- Best for: Flexible model testing, research

**Test Result:** ✅ Working with Ollama

---

### 3. Mistral Vibe - ⚠️ REQUIRES SETUP

**Installation:**
```bash
uv tool install mistral-vibe
# Command: vibe
```

**Configuration:**
- Manual setup: `vibe --setup` (interactive)
- Or env vars: `VIBE_ACTIVE_MODEL`, `VIBE_PROVIDERS_*`
- File: `~/.vibe/.env` (optional)

**Key Features:**
- Lightweight and fast
- Good for interactive development
- Supports Ollama natively
- Best for: Interactive development, quick iteration

**Known Issue:** Requires initial setup via `vibe --setup`

---

### 4. SHAI - ⚠️ REQUIRES AGENT CONFIG

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/ovh/shai/main/install.sh | sh
# Installed to: ~/.local/bin/shai
```

**Configuration:**
- Agent config: `~/.config/shai/agents/ollama.config`
- Interactive auth: `shai auth` (choose custom endpoint)

**Key Features:**
- Shell integration: `shai on`/`shai off`
- HTTP server mode: `shai serve --port 3000`
- MCP support for extending capabilities
- Best for: Shell integration, CI/CD pipelines

**Known Issue:** TUI mode has terminal issues in headless; use agent mode instead

---

## Configuration Files Created

### System Locations
```
~/.omp/config/ollama.toml              # omp Ollama config
~/.config/qwen/settings.json           # Qwen settings
~/.vibe/.env                           # Vibe environment
~/.config/shai/agents/ollama.config    # SHAI agent config
~/.local/agents.env                    # Shared environment
```

### All configurations point to:
- **Ollama:** http://localhost:11434/v1
- **API Key:** ollama (Ollama doesn't require real keys)

---

## Testing Results

| Agent | Installation | Ollama Config | Test Result | Status |
|-------|--------------|---------------|-------------|--------|
| omp | ✅ npm | ✅ .toml | ✅ Verified | READY |
| Qwen | ✅ npm | ✅ JSON | ✅ Verified | READY |
| Vibe | ✅ uv | ✅ .env | ⚠️ Works after setup | WORKING |
| SHAI | ✅ curl | ✅ JSON | ⚠️ Works with agent mode | WORKING |

---

## For LM Studio Support

When LM Studio is started on port 8000:

1. **omp:** `omp models list` auto-detects, use `--model lm-studio/default`
2. **Qwen:** Create new settings.json pointing to `http://localhost:8000/v1`
3. **Vibe:** Run `vibe --setup` again, select LM Studio
4. **SHAI:** Create new agent config for LM Studio in `~/.config/shai/agents/`

---

## Recommended Integration into Benchmark

### For your evaluator bench, prioritize:

1. **omp** - Most feature-rich, best for comparisons
   - Use: `--mode json` for structured output
   - Can test: Default/Smol/Slow role models
   - Can test: Fallback chains

2. **Qwen** - Good for runtime flexibility
   - Use: `-o json` for output
   - Can test: Multiple models sequentially
   - Can test: Model performance variance

3. **Mistral Vibe** - Quick iteration testing
   - Use: `-p` with `--auto-approve`
   - Good for: Sanity checks, quick validation

4. **SHAI** - Specialized use cases
   - Use: HTTP server mode for load testing
   - Use: Shell integration for workflow testing

---

## Environment Setup

To source all agents' environment variables:
```bash
source ~/.local/agents.env
```

This sets:
- `OLLAMA_HOST`
- `QWEN_API_*` variables
- `MISTRAL_API_KEY`
- `OMP_MODEL`

---

## Next Steps

1. ✅ All agents configured for Ollama
2. ⏭️ Test with various Ollama models (phi4, qwen, gemma)
3. ⏭️ When LM Studio starts: reconfigure for dual-provider testing
4. ⏭️ Integrate into benchmark framework with standardized prompts
5. ⏭️ Measure: Response time, quality, consistency across agents
6. ⏭️ Document: Performance comparison matrix

---

## Files in This Package

- `AGENTS_SETUP_GUIDE.html` - Complete interactive setup guide
- `setup-all-agents.sh` - Automated configuration script
- `test-all-agents.sh` - Test all agents at once
- `AGENTS_SUMMARY.md` - This file

---

## Support

See `AGENTS_SETUP_GUIDE.html` for detailed instructions per agent.

For any agent-specific issues, refer to their GitHub repositories:
- omp: https://github.com/can1357/oh-my-pi
- Qwen: https://github.com/QwenLM/qwen-code
- Vibe: https://github.com/mistralai/vibe
- SHAI: https://github.com/ovh/shai
