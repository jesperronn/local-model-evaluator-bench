# Adapter setup: documentation + pre-configuration = zero friction

**Principle**: Adapters ship documentation + pre-configured global settings so users never hit "why isn't this working?" before they even start using them.

## Adapter compatibility

### ✅ Recommended for local models
**aider**, **cline**, **hermes**, **opencode**, **pi** — tested and stable across multiple models and runtimes.

### ⚠️ Limited support or slow
**caveman**, **codex**, **interpreter**, **openhands**, **nanocoder**, **cn**, **goose**, **gptme** — work but may be slower, resource-intensive, or have edge cases. See [TESTING-STRATEGY.md](TESTING-STRATEGY.md) for coverage status.

### ❌ Incompatible with local models
**copilot** — requires the cloud-hosted Anthropic API. Uses cloud-specific patch formats that local open-source models don't produce. Cannot be adapted for local use without fundamental rewrites. [See compat.json](../compat.json) for known failures.

**claude** — Stainless SDK incompatibility with local model servers. The SDK expects tool execution feedback that LM Studio's OpenAI endpoint doesn't provide, causing file creation to silently fail. Unfixable without changes to the SDK or server implementation. [See ADAPTER-TEST-RESULTS.md](ADAPTER-TEST-RESULTS.md) for diagnostic details.

**mini-swe-agent** (v2.4.2) — Non-interactive stdin incompatible. Always prompts for model/API setup, even with `--model` flag, `.env` pre-config, or `MINI_CONFIG_INTERACTIVE=0`. Root cause: Early initialization before CLI parsing treats piped stdin as input to interactive prompt, not the task. [See DEPRECATED-mini-swe-agent.md](models/DEPRECATED-mini-swe-agent.md) for details and revisit options.

**forge** — better-sqlite3 native binding incompatible. Tool crashes on startup; the required native SQLite binding won't compile on arm64 macOS despite rebuild attempts, npm reinstall, and Xcode tools. Blocker: requires C/C++ compilation environment with compatible pre-built binaries. [See DEPRECATED-forge.md](models/DEPRECATED-forge.md) for revisit options.

---

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

## Detecting and registering new models: bin/scout + bin/sync

Downloading a model (`lms get ...` / `ollama pull ...`) does not make it usable
here — it needs an entry in `models.txt` / `models-ollama.txt`, **and** an
entry in `~/.config/llmrun/agents.json` (section 2 above), before any adapter
runs it configured correctly. Being listed in `models.txt` without global
config is exactly the "adapter starts but is misconfigured" trap this doc
opened with — a model can be "registered" and still run every adapter with
unset context/temperature. `bin/scout` checks both; two commands close the
gap, and are meant to be simple enough for workshop participants (not just
benchmark maintainers) to run on their own:

```bash
# See what's missing — new downloads AND registered-but-unconfigured models
bin/scout
# NOTE: new model not registered globally: qwen/qwen3.5-9b (lms)
# bin/sync --provider lms --model qwen/qwen3.5-9b --agent aider,cline,hermes,opencode,pi
#
# NOTE: no global config for qwen/qwen3-coder-30b (lms) — adapters will use unset context/temperature
# bin/sync --provider lms --model qwen/qwen3-coder-30b --agent aider,cline,hermes,opencode,pi

# Copy-paste the suggested command (or edit the --agent list to whatever you want to test)
bin/sync --provider lms --model qwen/qwen3.5-9b --agent opencode,pi
```

`bin/sync` appends the model to the right models list and seeds
`~/.config/llmrun/agents.json` via `bin/suggest-tuning` — registration only,
no model load. It prints a `bin/smoke` command as the next step for whoever
wants to actually prove the model works before relying on it (that step is
slow, so it's opt-in rather than automatic).

`bin/scout` is read-only and never deletes: if a model is registered in
`models.txt`/`models-ollama.txt` but no longer downloaded, it's flagged
("registered but not downloaded") and left alone — that's a job for
[`bin/prune`](../bin/prune), not `bin/scout`.

For every downloaded model it also prints a per-(model, agent) breakdown,
checking the actual config file each agent reads at launch
(`~/.pi/agent/models.json`, `~/.config/opencode/opencode.jsonc`) rather than
just the shared `~/.config/llmrun/agents.json` store:

```
[PASS] model: qwen/qwen3.6-35b-a3b   agent: pi         exists in /Users/you/.pi/agent/models.json
[FAIL] model: google/gemma-4-e4b     agent: opencode   missing from /Users/you/.config/opencode/opencode.jsonc (run: bin/sync ... --agent opencode)
[SKIP] model: qwen/qwen3.6-35b-a3b   agent: aider      no per-model list — launched with --model directly
```

`aider`/`hermes`/`cline` take `--model` directly at launch (no per-model
registration file), so they're reported `SKIP`, not `FAIL`.

## Integration points

- `bin/scout` / `bin/sync` — detect + register models missing from the bench's model lists (see above)
- `bin/build-llmrun` — calls `llmrun agents config list --opencode-only` to seed the opencode config during build (if opencode is present)
- `bin/doctor` — shows which adapters are installed + which global configs exist (as a readiness check)
- Setup workflows (TBD) — e.g., `bin/setup` or `bin/init` could run `bin/suggest-tuning | llmrun agents config apply --write` to auto-seed new machines

## Implementation status

**Pre-configuration (✓ done)**:
- [bin/suggest-tuning](../bin/suggest-tuning) reads model cards (`docs/models/*.md`) and extracts:
  - **Context window** from "**Context window**" metadata row
  - **Temperature** = 0.7 (from `ADAPTER_DEFAULT_TEMPERATURE` in config.sh)
  - **Max tokens** = 8192 (from `ADAPTER_DEFAULT_MAX_TOKENS` in config.sh)
- Emits plan.jsonl rows: `{model, key, value, reason, source}` for `llmrun agents config apply`
- `llmrun agents config apply plan.jsonl --write` writes settings to `~/.config/llmrun/agents.json`
- `llmrun agents config {get,set,unset,list,apply}` provide the UI (in [bin/build-llmrun](../bin/build-llmrun))
- Test suite: [bin/suggest-tuning.test.sh](../bin/suggest-tuning.test.sh)

**Usage**: 
```bash
# Generate plan from model cards
bin/suggest-tuning > /tmp/plan.jsonl

# Preview what will be set (dry-run)
llmrun agents config apply /tmp/plan.jsonl

# Apply to global config
llmrun agents config apply /tmp/plan.jsonl --write

# Verify settings took effect
llmrun agents config get qwen/qwen3.6-35b-a3b context
# → 65536
llmrun agents config get qwen/qwen3.6-35b-a3b temperature
# → 0.7
```

**Documentation (TBD)**:
- Card templates: add "Launching" section with example commands
- Model card Quick verdict: add "Launching" subsection per model
- See [docs/PLAN-CLI-UNIFICATION.md](PLAN-CLI-UNIFICATION.md) for related config CRUD design

## Success criteria

**When this is done:**
1. A user installs an adapter (e.g., `pip install aider`)
2. Runs `bin/suggest-tuning | llmrun agents config apply --write` to pre-configure
3. Runs an adapter (e.g., `llmrun --agent aider --model hermes`) from a card or copied from a model doc
4. It works immediately — no manual config tweaking, no "context window too small" errors that the project could have prevented
