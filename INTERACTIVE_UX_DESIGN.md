# Interactive Agent Setup - UX/DX Design

## Design Goals

1. **Zero Manual Configuration** - Discover everything automatically
2. **Guided Choices** - Help users make decisions without overwhelming them
3. **Fast Validation** - Test configs immediately, fail fast
4. **Clear Feedback** - Every action shows clear outcome
5. **Safe Defaults** - Pre-select sensible options
6. **Easy Rollback** - "Undo" if something goes wrong

---

## Flow Overview

```
Start
  ↓
Detect Servers (Ollama, LM Studio, custom?)
  ↓
List Available Models per Server
  ↓
For Each Agent:
  - Show features/capabilities
  - Let user choose to configure or skip
  - Select primary model
  - Select backup model (optional)
  ↓
Review All Choices
  ↓
Test Each Agent
  ↓
Save Configurations
  ↓
Next Steps (integrate, test, benchmark)
```

---

## Phase 1: Server Discovery

### What it discovers:
```
✓ Ollama on localhost:11434
✓ LM Studio on localhost:8000
✓ Custom endpoints (user-provided)
✓ OpenAI/Anthropic/Mistral API keys (optional)
```

### User experience:
```
🔍 Discovering local model servers...

Found:
  ✅ Ollama          http://localhost:11434/v1
     Models: phi4, qwen3.5:9b, gemma4 (3 total)
  
  ❌ LM Studio       http://localhost:8000/v1
     (not running, but can be configured)
  
  ❓ Custom endpoint? (y/n)
     → User can add one if they have it
```

### Advanced: Server Configuration Menu

```
┌─ Model Servers ──────────────────────────┐
│ 1. Use Ollama                [detected]  │
│ 2. Use LM Studio             [offline]   │
│ 3. Add custom endpoint       [manual]    │
│ 4. Add API provider (Mistral)[manual]    │
│                                          │
│ Which would you like to configure? (1-4)│
└──────────────────────────────────────────┘
```

---

## Phase 2: Agent Selection & Configuration

### Show what we know about each agent:

```
┌─ Agent: omp (Pi Coding Agent) ────────────────────┐
│ Status:          ✅ Installed (v16.3.6)           │
│ Features:                                          │
│   • Auto-detects local models                     │
│   • Fallback chains for resilience                │
│   • Role-based models (smol/slow/default)         │
│   • JSON output mode                              │
│                                                    │
│ Configure this agent? (y/n/help)                  │
│ → If yes, shows model selection                   │
└────────────────────────────────────────────────────┘
```

### Model Selection for Each Agent:

```
Primary model for omp:
  1. ollama/qwen3.5:9b      [general purpose] ← DEFAULT
  2. ollama/phi4:latest     [lightweight]
  3. ollama/qwen2.5-coder   [code focused]
  4. lm-studio/default      [LM Studio]
  5. Enter custom model name
  
  → Select (1-5): [1]

Backup model for fallback?
  1. (none) ← RECOMMENDED
  2. ollama/phi4:latest
  3. ollama/qwen2.5-coder
  
  → Select (1-3): [1]
```

### Keep it Simple:

For each agent, just ask:
```
Configure [Agent Name]? (y/n)
  Primary model: [dropdown with defaults]
  Backup model: [dropdown or none]
  Skip? [go to next agent]
```

---

## Phase 3: Review & Confirm

Show summary before saving:

```
╔════ Configuration Summary ════╗
│                               │
│ Servers:                      │
│  • Ollama (primary)           │
│  • LM Studio (fallback)       │
│                               │
│ Agents to Configure:          │
│  1. omp → qwen3.5:9b          │
│  2. qwen → qwen3.5:9b         │
│  3. vibe → (skip)             │
│  4. shai → ollama             │
│                               │
│ Save these settings? (y/n)    │
│                               │
╚═══════════════════════════════╝
```

If user says "n", show:
```
What would you like to change?
  1. Add/remove agent
  2. Change model for [agent]
  3. Start over
  4. Cancel and exit
```

---

## Phase 4: Testing

After saving, ask:
```
✅ Configurations saved!

Would you like to test agents now? (y/n)
  → Tests each agent with: "Write a hello world in Python"
  → Shows success/failure
  → Provides next steps
```

Test output:
```
Testing omp...          ⏳ [████░░░░░░] 50%
  Response preview: def hello_world():...

Testing qwen...         ✅ Complete (2.3s)
Testing vibe...         ⏭️  Skipped
Testing shai...         ✅ Complete (1.8s)

All tests complete!
Summary: 3 working, 0 failed, 1 skipped
```

---

## Phase 5: Next Steps

Smart context-aware suggestions:

```
🎉 Setup complete!

Next steps:
  1. Run benchmark: ./bench.sh
  2. Test with custom prompt: omp -p "your prompt"
  3. Start interactive: qwen
  4. View full docs: open AGENTS_SETUP_GUIDE.html
  5. Add LM Studio later: ./agents-setup --add-server

Save as default? (y/n)
  → Creates ~/.agents-config.json for future runs
```

---

## UX Details - Make it Friendly

### Colors & Icons
```
✅ Success        → Green + checkmark
❌ Error/Missing  → Red + X
⏳ In Progress    → Yellow + spinner
⏭️  Skipped       → Gray + skip icon
ℹ️  Info          → Blue + info icon
❓ Question       → White + ?
```

### Keyboard Shortcuts
```
Space/Enter  → Select/Confirm
y/n          → Yes/No quick answers
↑/↓          → Navigate lists
ESC          → Cancel current step (with confirmation)
?            → Show help for current screen
```

### Error Handling
```
❌ Can't reach Ollama on localhost:11434
   
   Would you like to:
     1. Try a different port
     2. Skip Ollama for now
     3. Get help troubleshooting
     
   → Select (1-3):
```

### Safe Defaults
```
# When showing options, pre-select the best choice:
1. ollama/qwen3.5:9b       [RECOMMENDED]  ← pre-selected
2. ollama/phi4:latest
3. ollama/gemma4:12b

# Visual indication:
→ = currently selected
✓ = recommended
```

---

## Advanced Features (Phase 2)

### Config Profiles
```
Save this as a profile? (y/n)
  Profile name: [benchmark-ollama]
  
# Later:
./agents-setup --profile benchmark-ollama
```

### Diff/Compare
```
Changes from last saved config:
  + Added: omp with qwen3.5:9b
  - Removed: vibe configuration
  ~ Changed: shai primary model

Apply these changes? (y/n)
```

### Environment Variable Export
```
Export as shell script? (y/n)
  → Creates: ~/.agents-env.sh
  
  Usage: source ~/.agents-env.sh
```

---

## Implementation Strategy

### Technology Stack:
- **Shell script** (bash) with `fzf` for interactive selection
- **Color codes** via `tput` or ANSI escape sequences
- **Spinners** for progress
- **JSON** for config storage
- **Validation** via actual API calls (test connectivity)

### Key Functions:
```bash
discover_servers()        # Find Ollama, LM Studio, etc.
list_models()            # Get models from each server
show_agent_menu()        # Select agents to configure
select_models()          # Choose models for each agent
validate_config()        # Test each agent
save_config()           # Write to ~/.config/*
test_agents()           # Run quick tests
show_next_steps()       # Context-aware help
```

### Config Storage:
```json
{
  "servers": {
    "ollama": { "url": "http://localhost:11434/v1", "available": true },
    "lm_studio": { "url": "http://localhost:8000/v1", "available": false }
  },
  "agents": {
    "omp": {
      "enabled": true,
      "primary_model": "ollama/qwen3.5:9b",
      "backup_model": null
    },
    "qwen": {
      "enabled": true,
      "primary_model": "ollama/qwen3.5:9b"
    }
  },
  "created_at": "2026-07-05T...",
  "last_updated": "2026-07-05T..."
}
```

---

## Example Session Flow

```
$ ./agents-setup

🤖 Interactive Agent Setup & Discovery
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Discovering local model servers...
  ✅ Found Ollama at http://localhost:11434
  ✅ Found 5 models in Ollama
  ❌ LM Studio not running (can configure later)

Would you like to configure any agents? (y/n): y

┌─ Agents ─────────────────────────────────┐
│ ✓ omp (Pi Coding)     [installed]        │
│ ✓ qwen (Qwen Code)    [installed]        │
│   vibe (Mistral)      [installed]        │
│   shai (SHAI)         [installed]        │
│                                          │
│ Select agents to configure (space=toggle)│
│ Enter when done                          │
└──────────────────────────────────────────┘

→ omp
  Primary: [qwen3.5:9b] ← most popular
  Backup: [none]
  ✓ Saved

→ qwen
  Primary: [qwen3.5:9b]
  Backup: [phi4:latest]
  ✓ Saved

→ vibe
  Skip? (y/n): y
  ✓ Skipped

→ shai
  Primary: [phi4:latest]
  Backup: [none]
  ✓ Saved

╔════ Configuration Complete ════╗
│ 3 agents configured            │
│ 1 agent skipped                │
│ 2 model servers available      │
│                                │
│ Test agents now? (y/n)         │
╚════════════════════════════════╝
: y

Testing agents...
  omp:   ✅ (2.1s)
  qwen:  ✅ (1.8s)
  shai:  ✅ (1.5s)

All tests passed! 🎉

Your config is ready. Next:
  • Run agents: omp -p "prompt"
  • View docs: open AGENTS_SETUP_GUIDE.html
  • Add LM Studio: ./agents-setup --add-server
```

---

## Questions for Implementation

1. **CLI or TUI?** 
   - CLI with `fzf` menus (simpler, more portable)
   - vs. Full TUI (prettier, more interactive)

2. **How many questions?**
   - Minimal: just "which servers, which agents?"
   - vs. Detailed: "all features explained per agent?"

3. **Save location?**
   - `~/.agents-setup.json` (simple, one file)
   - vs. Distributed (omp → ~/.omp/config, etc.)

4. **Speed vs. Completeness?**
   - Fast path: auto-select defaults (30 seconds)
   - vs. Expert mode: all options (5 minutes)

---

## What do you think?

Which aspects matter most for your use case?

1. **Speed** - Get configured in < 1 minute
2. **Safety** - Test everything before saving
3. **Flexibility** - Support many server/model combos
4. **Learning** - Explain what each agent does
5. **Integration** - Seamlessly add to benchmark

Should we build the MVP script first and iterate?
