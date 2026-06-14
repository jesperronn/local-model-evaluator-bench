# Plan: llmrun — universal adapter launcher

## Metadata

| Field | Value |
|---|---|
| **Date** | 2026-06-13 |
| **Session start** | 2026-06-13T14:49:01Z (Europe/Copenhagen, UTC+2) |
| **Plan created** | 2026-06-13T14:52:31Z |
| **Duration** | ~3.5 minutes |
| **Input question** | "we need to add copilot (local) and claude (local) to the list tools since it is possible." → "lets consider if we can use findings of this project to build a launcher (adapter) so that with one command we can launch interactively or preselect with --tool --runtime --model flags, will fail with useful next steps if launcher/model/runtime is missing, the command can be rebuilt any times based on future findings" → "How would we plan to do this??" |
| **Tool** | GitHub Copilot CLI — model `qwen/qwen3.6-35b-a3b` (model ID: qwen/qwen3.6-35b-a3b) |
| **Chosen name** | `llmrun` |
| **Contenders** | `llmstart`, `llmtool` |

---

## Goal

A single `llmrun` command that:

1. Selects tool + runtime + model (from flags or fzf pickers)
2. Validates prerequisites with actionable error messages
3. Execs the matching adapter (interactive or prompted)
4. Stays rebuildable as adapters evolve — no hardcoded knowledge

---

## Design

### Entry

```
bin/launch [--tool <name>] [--runtime <lms|mlx|ollama>] [--model <id>] [prompt...]
```

### Phase 1 — Select

Each axis falls back to an fzf picker if the flag is not given:

| Axis | Flag given | Flag absent |
|---|---|---|
| Tool | use it | fzf from unique tool names in `adapters/*.sh` |
| Runtime | use it | fzf from unique runtimes in `adapters/*.sh` |
| Model | use it | fzf from `lms ls` / `ollama list` / `models-mlx.txt` |

Source of truth for available tools and runtimes: **adapter filenames** (`adapters/<tool>-<runtime>.sh`). No hardcoding.

### Phase 2 — Validate (fail fast with next steps)

| Check | On failure |
|---|---|
| `adapters/<tool>-<runtime>.sh` exists | List available combos; suggest closest match |
| Runtime reachable (`lms_up` / curl ollama / curl mlx) | Print start command (`lms server start`, `ollama serve`, etc.) |
| Tool binary on PATH (`command -v <tool>`) | Print install hint extracted from `# Adapter:` comment in the adapter file |

Validation helpers from `lib/common.sh`: `lms_up`, `lms_loaded_models`.

### Phase 3 — Exec

Prompt source, in priority order:

1. `prompt...` args given → `echo "$*" | MODEL_ID=... adapter`
2. stdin is a pipe → pipe through: `MODEL_ID=... adapter` (stdin forwarded)
3. Neither → interactive: `MODEL_ID=... adapter` (adapter detects tty, skips prompt flag)

The adapter itself handles the tty detection (`[ -t 0 ]`) — launcher just needs to exec it.

### Rebuildability

Everything derives from the project at runtime:

- **Tool + runtime list** — parsed from `adapters/*.sh` filenames
- **Model list** — queried live from the chosen runtime
- **Install hints** — extracted from the `# Adapter: ...` header comment already in every adapter
- **LMS/API defaults** — sourced from `config.sh` (adapters already do this)
- **Preferred model** — `PREFERRED_MODEL_ID` in `config.sh`

Adding a new adapter (e.g. `claude-lms.sh`) makes it immediately discoverable. No changes to `bin/launch` needed.

---

## Open question before building

Should `bin/launch` auto-load the model in LM Studio (like `bin/bench` does), or validate it's loaded and print instructions if not?

- **Auto-load**: more ergonomic for one-shot use; adds `lms load` + TTL/context params complexity
- **Validate only**: simpler launcher; user handles loading (they likely already have a model loaded for interactive use)

**Recommendation**: validate-only for v1. Add auto-load as an opt-in flag (`--load`) later.

---

## Files to create / modify

| File | Action |
|---|---|
| `bin/launch` | Create (new script) |
| `lib/common.sh` | Possibly add `ollama_up`, `mlx_up` helpers if not present |
| `config.sh` | No changes needed |
| `adapters/*.sh` | No changes needed |
