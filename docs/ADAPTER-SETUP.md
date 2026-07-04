# Adapter setup: documentation + pre-configuration = zero friction

**Principle**: Adapters ship documentation + pre-configured global settings so users never hit "why isn't this working?" before they even start using them.

Two pieces work together:

## 1. Documentation: launch commands on every card

Each adapter (aider, cline, codex, opencode, hermes) needs a "how to launch" section in two places:

**Card template** — when a user creates a new card with `bin/cards create`, the template should include:
```bash
# Launch with aider:
llmrun --agent aider --model <your-model> --runtime <lms|ollama|mlx>

# Launch with cline:
llmrun --agent cline --model <your-model> --runtime <lms|ollama|mlx>
```

**Model card** — each `docs/models/*.md` should include a "Launching" or "Adapters" subsection listing which adapters work well with that model and how to invoke them:
```markdown
## Launching

- **aider**: `llmrun --agent aider --model qwen/qwen3.6-35b-a3b --runtime lms`
- **cline**: (not recommended for this model — context window too small)
- **codex**: `llmrun --agent codex --model ... --runtime ollama`
```

**Why**: Users copy-paste commands directly. No hunting through READMEs or guessing syntax.

## 2. Pre-configuration: global settings that "just work"

Before a user ever runs an adapter, this project generates a plan of recommended settings — per model, per adapter — and applies them globally. This avoids the "adapter starts but is misconfigured" problem.

**How it works**:

1. **bin/suggest-tuning** reads evidence from repo (model cards, README hard requirements) and emits a plan:
   ```jsonl
   {"model": "qwen/qwen3.6-35b-a3b", "key": "context", "value": 65536, "reason": "model card Quick verdict", "source": "docs/models/qwen--qwen3.6-35b-a3b.md"}
   {"model": "qwen/qwen3.6-35b-a3b", "key": "temperature", "value": 0.7, "reason": "good default for coding", "source": "config.sh"}
   ```

2. **llmrun agents config apply plan.jsonl** reads the plan and writes settings to:
   - `~/.config/llmrun/agents.json` (global agent config store)
   - `~/.config/opencode/opencode.jsonc` (opencode-specific)
   - `~/.pi/agent/models.json` (pi-specific)
   - etc. (one per tool that has config)

3. **Adapters read from these files at startup** — no manual setup needed. Temperature, context window, tool-call behavior are already tuned.

**Why this split**:

- **Suggestion** (`bin/suggest-tuning`) is repo-aware. It reads *this project's* model cards and README to decide what values should be. It never writes.
- **Application** (`llmrun agents config apply`) is machine-aware. It reads the plan and writes to the machine's actual config files (which may differ by OS, installation path, user preference).
- **Separation of concerns**: The project judges *what*, the machine applies *how*. A user can override a suggested setting without breaking the repo.

## Integration points

- `bin/build-llmrun` — calls `llmrun agents config list --opencode-only` to seed the opencode config during build (if opencode is present)
- `bin/doctor` — shows which adapters are installed + which global configs exist (as a readiness check)
- Setup workflows (TBD) — e.g., `bin/setup` or `bin/init` could run `bin/suggest-tuning | llmrun agents config apply --write` to auto-seed new machines

## Success criteria

**When this is done:**
1. A user installs an adapter (e.g., `pip install aider`)
2. Runs `llmrun --agent aider --model hermes` (from a card, or copy-pasted from a model doc)
3. It works immediately — no manual config tweaking, no "context window too small" errors that the project could have prevented
