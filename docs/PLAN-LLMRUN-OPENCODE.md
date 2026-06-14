# Plan: `llmrun` — interactive launcher for the benchmark harness (opencode)

**Status**: proposed
**Created**: 2026-06-13T14:52Z
**Created by**: opencode (lmstudio/qwen/qwen3.6-35b-a3b)
**Input question**: "lets consider if we can use findings of this project to build a launcher (adapter) so that with one command we can launch interactively or preselect with --tool --runtime --model flags, will fail with useful next steps if launcher is missing / model is missing / runtime is missing, the command can be rebuilt any times based on future findings and research in this project"
**Planning time**: ~12 minutes
**Primary name**: `llmrun`
**Contenders**: `llmstart`, `llmtool`
**Other options considered**: `llmgo`, `llmdeck`, `llmpilot`, `llmforge`, `llmexec`, `llmshell`, `llmkit`, `llmwork`, `llmcraft`

---

## Problem

Today, running a coding task against a local model requires juggling multiple commands:

```
lms load <id> --context-length 65536 --parallel 4 --ttl 3600 --yes
adapters/aider-lms.sh          # or opencode-lms.sh, hermes-mlx.sh, etc.
```

No single entry point. No validation. No auto-discovery. No actionable errors.

## Goal

One command that works whether you pass flags or need a picker:

```bash
# Pre-selected
llmrun --tool opencode --runtime lms --model qwen3.6-35b-a3b --case js-03-multifile-cache

# Interactive (all four axes)
llmrun

# Interactive (two axes already given — skips those pickers)
llmrun --tool hermes

# Dry run — show what would execute
llmrun --tool aider --model qwen3.5-9b --case js-01-slugify-bug --dry-run
```

Fails fast with **actionable next steps** when something is missing, not a cryptic error.

---

## Architecture

```
`llmrun` (installed on PATH)
├── Discovery (reads project data, no hardcoding)
│   ├── tools  → adapters/*.sh that are on PATH
│   ├── runtimes → which of {lmstudio, ollama, mlx} is installed/running
│   ├── models → models-aliases.conf + models.txt + lms ls/ollama list
│   └── cases  → cases/*/meta.json
│
├── Selection
│   ├── flags given → validate
│   └── no flags → fzf cascading picker (runtime → tool → model → case)
│
├── Validation (fail-fast with actionable next steps)
│   ├── runtime up? → start command
│   ├── tool installed? → install command
│   ├── model downloaded for this runtime? → download/load command
│   ├── model loaded in memory? → offer to load
│   └── case exists? → list available
│
└── Execution
    ├── resolve alias → runtime-specific model id
    ├── load model if needed (lms load / ollama run)
    └── exec adapters/<tool>-<runtime>.sh with case prompt
```

---

## Key design decisions

### 1. Runtime-aware model resolution (reuses `models-aliases.conf`)

The alias file already maps cross-runtime ids. The launcher reuses this:

```
--model qwen3.6-35b-a3b --runtime ollama  →  qwen3.6:35b-a3b-coding-mxfp8
--model qwen3.6-35b-a3b --runtime mlx     →  (empty → "not available for mlx")
--model gemma4-claude  --runtime ollama   →  gemma4-claude
--model qwen3.5-9b     --runtime lms      →  qwen/qwen3.5-9b
```

The `-` entries in `models-aliases.conf` are the "not available" signal.

### 2. Adapter resolution

Adapter naming convention is already `adapters/<tool>-<runtime>.sh`:

```
tool=aider, runtime=mlx → adapters/aider-mlx.sh (if it exists)
tool=hermes, runtime=lms → adapters/hermes-lms.sh
```

If no `<tool>-<runtime>.sh` exists, show available runtimes for that tool.

### 3. Failure messages — concrete next steps

```
# Runtime not running (lmstudio):
[FAIL] LM Studio not reachable at http://localhost:1234/v1
  Start it:  lms server start
  Then retry, or use --runtime ollama or --runtime mlx

# Runtime not installed:
[FAIL] lmstudio not found on PATH
  Install:  brew install --cask lmstudio
  Then:  lms server start

# Model not downloaded:
[FAIL] Model "qwen/qwen3.5-9b" not downloaded in LM Studio
  Download:  lms get qwen/qwen3.5-9b
  Then load: lms load qwen/qwen3.5-9b --context-length 65536

# Model not loaded:
[WARN] Model "qwen/qwen3.5-9b" not loaded — load it? [Y/n]
  → loads with BENCH_CONTEXT + BENCH_PARALLEL defaults

# Tool not installed:
[FAIL] "hermes" not found on PATH
  Install:  pipx install hermes-agent  (or your install method)
  See docs/SETUP.md for hermes config requirements

# No adapter for this (tool, runtime) pair:
[FAIL] No adapter for hermes + mlx
  Available adapters: hermes-lms.sh, hermes-ollama.sh
  Run:  llmrun --tool hermes --runtime lms   (or ollama)
```

### 4. Interactive picker flow

```
$ llmrun

  runtime?  [lmstudio (3 models)]  [ollama (5 models)]  [mlx (3 models)]
  → lmstudio

  tool?  [aider]  [opencode]  [codex]  [caveman]  [hermes]
  → opencode

  model?  [qwen3.6-35b-a3b]  [qwen3.5-9b]  [gemma4-26b-qat]  [qwen3-coder-30b]  [qwen3-coder-next]
  → qwen3.6-35b-a3b

  case?  [smoke-00-hello]  [js-01-slugify-bug]  [js-02-debounce-feature]  [ts-01-groupby]  [bash-01-topwords]
         [js-03-multifile-cache]  [js-04-multifile-rename]  [js-05-multiselect-filter]  [js-06-lint-and-test]
  → js-03-multifile-cache

→ Running: opencode-lms.sh with qwen/qwen3.6-35b-a3b on js-03-multifile-cache
```

### 5. Rebuildability

Nothing is hardcoded. Everything comes from:

- `config.sh` — base URL, defaults, TTL, context, parallel
- `models.txt` — models under test
- `models-aliases.conf` — cross-runtime id mapping
- `adapters/` — available tool-runtime pairs
- `cases/*/` — available test cases
- `lms ls`, `lms ps`, `ollama list` — live discovery

When you add a model, adapter, or case, `llmrun` picks it up automatically.

---

## Implementation phases

### Phase 1 — Core

- Parse flags: `--tool`, `--runtime`, `--model`, `--case`, `--list`, `--interactive`
- Discovery from config files + CLI checks
- Validation with actionable error messages
- Execute the right adapter with resolved model id
- Model auto-load when missing
- Single script (~300-400 lines) with sourced `lib/launch-common.sh`

### Phase 2 — Interactive

- fzf cascading picker (runtime → tool → model → case)
- Color-coded status indicators (loaded / downloaded / missing)
- `--dry-run` to show what would execute

### Phase 3 — Smart defaults

- `--recommended` flag: best model for a tool based on benchmark data
- `--fast` flag: smallest model that passes the case
- Auto-detect and prefer runtimes that have the model loaded
- `--load` flag: load model with sensible defaults (context, parallel, TTL)

---

## File structure

```
llmrun          # main script (on PATH)
lib/launch-common.sh  # shared: discovery, validation, resolution
```

---

## What it replaces today

| Today | With `llmrun` |
|-------|---------------|
| `lms load <id>` + `adapters/aider-lms.sh` | `llmrun --tool aider --model qwen3.5-9b` |
| `lms load <id>` + `adapters/opencode-lms.sh` | `llmrun --tool opencode --model qwen3.5-9b` |
| Manual adapter discovery | Auto-discovers all `<tool>-<runtime>.sh` on PATH |
| Manual model lookup | Resolves aliases, checks loaded state, offers to load |

---

## Open questions

1. Should `--case` default to interactive picker, or require explicit selection?
2. Should it auto-load models? (Yes, with confirmation.)
3. Should `--recommended` exist? (Pulls from benchmark results.)
4. Output language preference? (English vs Danish?)

---

## Design criteria (from project)

- **Favour modern-efficiency architectures** — the launcher should surface the same guidance the project already has: prefer MLX on Apple Silicon, MoE/A3B for small-footprint accuracy, QAT for quantized fidelity, MTP for speed.
- **One endpoint** — everything points at LM Studio's OpenAI-compatible server (or ollama/mlx). The launcher picks the right one.
- **Ease of setup** — adding a model = one line in `models.txt`. The launcher discovers it automatically.
