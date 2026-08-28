# Interactive Setup Script - User Guide

## Overview

The `agents-setup` script combines **speed** and **learning**:
- ⚡ Get running in ~1 minute
- 📚 Understand why you're making choices
- 🧪 Auto-validate everything
- 🎯 Smart defaults you can trust

---

## Usage

```bash
bash agents-setup
```

That's it! The script handles everything else.

---

## What You'll See (Example Flow)

### Phase 1: Server Discovery (10 seconds)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Phase 1: Discovering Local Model Servers
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking Ollama... ✅ Found Ollama with 5 models
   Sample models:
     • phi4:latest
     • qwen3.5:9b
     • gemma4:12b-mlx

Checking LM Studio... ⚠️  LM Studio not running (localhost:8000)

Add custom endpoint? (y/n) [n]: n

✅ Found 1 server(s) configured
```

**What's happening:** 
- Auto-discovers what's actually running
- Shows you what models are available
- No manual configuration needed

---

### Phase 2: Agent Selection (20 seconds)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Phase 2: Configure Agents
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Which agents would you like to configure?

🎯 omp (Pi Coding Agent)
   Best for: Production automation, benchmarking
   Why: Auto-detects models, supports fallback chains, JSON output
   Speed: ⚡⚡⚡ (fast, reliable)

Configure omp? (y/n) [y]: y

🎯 Qwen Code (Alibaba's Agent)
   Best for: Flexible testing, switching models at runtime
   Why: Runtime model selection (-m flag), session mgmt
   Speed: ⚡⚡ (good, slightly slower startup)

Configure qwen? (y/n) [y]: y

🎯 Mistral Vibe (Mistral's Agent)
   Best for: Quick iteration, interactive development
   Why: Lightweight, fast startup, good for ad-hoc use
   Speed: ⚡⚡⚡⚡ (fastest, lightweight)

Configure vibe? (y/n) [y]: n

🎯 SHAI (OVH's Agent)
   Best for: HTTP API, shell integration, specialized use
   Why: Runs as server, shell hooks, MCP support
   Speed: ⚡⚡ (moderate, server-based)

Configure shai? (y/n) [y]: n

✅ Selected: omp qwen
```

**What's happening:**
- You read why each agent exists (not just feature lists)
- You understand the trade-offs (speed vs flexibility)
- You make informed choices, not just random selections

---

### Phase 3: Model Selection (10 seconds)

```
ℹ️  Selecting model for omp

Top models available:
  → ollama/phi4:latest
  → ollama/qwen3.5:9b
  → ollama/gemma4:12b-mlx

Select primary model (press Enter for default, or enter custom): 

✅ Selected: ollama/qwen3.5:9b

ℹ️  Selecting model for qwen

Top models available:
  → ollama/phi4:latest
  → ollama/qwen3.5:9b
  → ollama/gemma4:12b-mlx

Select primary model (press Enter for default, or enter custom): -m qwen3.5:9b

✅ Selected: qwen3.5:9b
```

**What's happening:**
- Shows you what's available
- Defaults to the most sensible choice (press Enter)
- But lets you pick something else if you want

---

### Phase 4: Summary & Confirm (5 seconds)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Configuration Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Servers:
  ✓ ollama

Agents to configure:
  ✓ omp → ollama/qwen3.5:9b
  ✓ qwen → qwen3.5:9b

Save these settings? (y/n) [y]: y

✅ Saving configurations...
✅ Saved: ~/.omp/config/agents-setup.toml
✅ Saved: ~/.config/qwen/settings.json
```

**What's happening:**
- You review everything before it's written
- Can go back and change if needed
- Clean, predictable config files in standard locations

---

### Phase 5: Testing (15 seconds)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 Testing Agents
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Testing omp... ✅ Working ✓
Testing qwen... ✅ Working ✓
```

**What's happening:**
- Actually runs each agent with a test prompt
- Confirms they work before you rely on them
- Catches configuration issues immediately

---

### Phase 6: Next Steps (Learning!)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 You're All Set!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your agents are configured and ready to use.

Quick Start:
  source ~/.local/agents.env  # Load environment

  omp -p "your prompt" --config ~/.omp/config/agents-setup.toml --auto-approve
  qwen -p "your prompt"

Next Steps:
  1. Integrate into your benchmark framework
  2. Test with various prompts and models
  3. When LM Studio starts: run this script again (--add-server)
  4. Compare performance across agents

Documentation:
  • Full guide: AGENTS_SETUP_GUIDE.html
  • Summary: AGENTS_SUMMARY.md

✅ Setup complete! Ready to benchmark.
```

**What's happening:**
- Context-aware next steps based on YOUR setup
- You know exactly what to do next
- Links to docs for deeper learning

---

## Design Philosophy

### Speed ⚡
- Auto-discover (no typing endpoints)
- Smart defaults (just press Enter)
- Parallel where possible (all checks happen at start)
- ~1 minute end-to-end

### Learning 🎓
- Explain **why** each agent exists
- Show speed/quality tradeoffs
- Help with next steps
- Link to deeper docs

### Safety 🛡️
- Test everything before saving
- Show summary before writing configs
- Easy to understand what changed
- Configs go to standard locations

### Integration 🔗
- Saves to standard `~/.config/*` locations
- Compatible with existing setups
- Can be run multiple times
- Handles upgrades/reconfiguration

---

## Advanced Usage

### Reconfigure Later

Just run the script again:
```bash
bash agents-setup
```

It will detect existing configs and ask if you want to update.

### Add a Server Later

When LM Studio starts:
```bash
bash agents-setup --add-server lm_studio
```

### Check Current Setup

```bash
bash agents-setup --show
```

Shows current configuration without changing anything.

---

## Troubleshooting

### "Ollama not running"

Start Ollama:
```bash
ollama serve
```

Then run the script again.

### "No models found"

Make sure you have models pulled in Ollama:
```bash
ollama pull qwen3.5:9b
ollama list
```

Then run the script again.

### "Agent test failed"

The script shows ⚠️ Partial (may work) because:
- Agent is slow to start first time
- Model is slow to load
- Configuration is slightly different

This is usually OK! The agents often work even if the test is slow.

To debug:
```bash
omp -p "hello" --config ~/.omp/config/agents-setup.toml --auto-approve
```

---

## What Gets Created

After running, you'll have:

```
~/.omp/config/agents-setup.toml       # omp configuration
~/.config/qwen/settings.json          # Qwen configuration
~/.vibe/.env                          # Vibe environment
~/.config/shai/agents/setup.config    # SHAI agent config
~/.config/agents-setup/               # Script metadata
```

All standard locations that tools expect.

---

## Key Features

### 1. Auto-Discovery
- Checks localhost:11434 (Ollama)
- Checks localhost:8000 (LM Studio)
- Asks about custom endpoints
- Lists actual available models

### 2. Educational
- Explains each agent's purpose
- Shows why you might pick it
- Indicates speed vs flexibility
- Links to deeper docs

### 3. Smart Defaults
- Pre-selects best choice per agent
- Just press Enter to accept
- Can easily override

### 4. Validation
- Tests each agent with real prompt
- Catches config issues early
- Shows what works vs partial

### 5. Context-Aware Next Steps
- Different suggestions based on your setup
- Links to relevant docs
- Integration guidance for your benchmark

---

## Extending the Script

### Add Support for New Agent

In the `show_agent_explanation()` function:

```bash
my_agent)
  echo "🎯 ${BOLD}My Agent${NC}"
  echo "   Best for: ..."
  echo "   Why: ..."
  echo "   Speed: ..."
  echo ""
  ;;
```

Then in Phase 5 (testing):

```bash
my_agent)
  if timeout 10 my-agent -p "$test_prompt" 2>/dev/null | grep -q "result"; then
    success "Working ✓"
  else
    warn "Partial (may work)"
  fi
  ;;
```

### Add Support for New Server

In `discover_servers()`:

```bash
# Check MyLLM
echo -n "Checking MyLLM... "
if curl -s http://localhost:9000/models > /tmp/myllm_models.json 2>/dev/null; then
  success "Found MyLLM"
  servers+=("myllm")
fi
```

Then in `get_available_models()`:

```bash
myllm)
  jq -r '.models[].name' /tmp/myllm_models.json 2>/dev/null | head -10
  ;;
```

---

## Next Steps

1. **Run it:** `bash agents-setup`
2. **Answer questions:** Just follow the prompts
3. **Start using agents:** `omp -p "your prompt"`
4. **Integrate:** Use in your benchmark
5. **Extend:** Add your own agents/servers as needed

---

## Questions?

- Confused about an agent? Run the script again, it'll explain
- Want to add a server? Edit the script or ask for help
- Want faster testing? You can skip tests: `--no-test`
- Want to see what would happen? Run with `--dry-run`

Enjoy! 🚀
