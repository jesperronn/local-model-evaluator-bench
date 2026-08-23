# Plan: Unify All Adapters Through LiteLLM Proxy

**Date:** 2025-08-22
**Goal:** Remove `--runtime` flag from all commands. All adapters talk to the
LiteLLM proxy. The proxy routes to the correct backend (lms, ollama, mlx, omlx,
mtplx) based on the model ID prefix: `lms/<id>`, `ollama/<id>`, etc.

## Why

- One endpoint (`$LITELLM_BASE_URL`) instead of five separate URLs.
- `llmrun` no longer needs `--runtime` — the proxy handles routing.
- `bin/bench` defaults to the proxy; model discovery queries the proxy's
  `/v1/models` which aggregates all backends.
- Adapters no longer need runtime-specific branches (edit format for mlx,
  diff flag for ollama, metadata file for omlx, etc.).

## Scope of Changes

### 1. `config.sh` — Add proxy defaults

Current state: `LITELLM_BASE_URL` and `LITELLM_PORT` exist but are unused by
adapters.

Changes:
- Add `LITELLM_PROXY_MODE=1` marker (optional, for clarity).
- Ensure `LITELLM_BASE_URL` defaults to `http://127.0.0.1:${LITELLM_PORT}/v1`.
- Adapters source `config.sh` and read `LITELLM_BASE_URL` as the endpoint.

### 2. All 58 adapter files — Rewrite to use the proxy

Current state: Each adapter connects directly to its specific runtime:
- `caveman-lms.sh` → `--provider lmstudio --model "$MODEL_ID"`
- `caveman-omlx.sh` → `--provider omlx --model "$MODEL_ID"`
- `openhands-lms.sh` → `LLM_BASE_URL=$LMS_BASE_URL`
- etc.

Changes per adapter group:

#### Group A: Unified adapters (no runtime suffix) — 1 file
| File | Current | New |
|------|---------|-----|
| `aider.sh` | Sources config.sh, reads `$RUNTIME`, branches on lms/ollama/mlx/omlx | Always uses `$LITELLM_BASE_URL` + `$LITELLM_API_KEY` (empty). Model addressed as `openai/<MODEL_ID>`. |

#### Group B: Agent-specific runtime adapters — ~50 files
Each follows the pattern `<agent>-<runtime>.sh`. The runtime suffix becomes
meaningless — the proxy routes based on the model ID prefix.

New naming convention: `<agent>.sh` (no runtime suffix).

For each agent, we consolidate all runtime variants into ONE adapter that
talks to the proxy:

| Agent | Current files | New file |
|-------|--------------|----------|
| caveman | caveman-lms.sh, caveman-mlx.sh, caveman-ollama.sh, caveman-omlx.sh | caveman.sh |
| claude | claude-lms.sh, claude-ollama.sh, claude-omlx.sh | claude.sh |
| cline | cline-lms.sh, cline-mlx.sh, cline-ollama.sh, cline-omlx.sh | cline.sh |
| cn | cn-lms.sh, cn-omlx.sh | cn.sh |
| codex | codex-lms.sh, codex-mlx.sh (stub), codex-ollama.sh, codex-omlx.sh | codex.sh |
| copilot | copilot-lms.sh, copilot-mlx.sh, copilot-ollama.sh, coplex-omlx.sh | copilot.sh |
| forge | forge-lms.sh, forge-omlx.sh | forge.sh |
| goose | goose-lms.sh, goose-omlx.sh | goose.sh |
| gptme | gptme-lms.sh, gptme-omlx.sh | gptme.sh |
| hermes | hermes-lms.sh, hermes-mlx.sh, hermes-ollama.sh, hermes-omlx.sh | hermes.sh |
| interpreter | interpreter-lms.sh, interpreter-ollama.sh | interpreter.sh |
| mini-swe-agent | mini-swe-agent-lms.sh, mini-swe-agent-omlx.sh | mini-swe-agent.sh |
| nanocoder | nanocoder-lms.sh, nanocoder-omlx.sh | nanocoder.sh |
| omp | omp-omlx.sh, omp-ollama.sh, omp-mtplx.sh | omp.sh |
| opencode | opencode-lms.sh, opencode-mlx.sh, opencode-ollama.sh, opencode-omlx.sh | opencode.sh |
| opencode-orch | opencode-orch-lms.sh | opencode-orch.sh |
| openhands | openhands-lms.sh, openhands-ollama.sh, openhands-omlx.sh | openhands.sh |
| pi | pi-lms.sh, pi-mlx.sh, pi-ollama.sh, pi-omlx.sh | pi.sh |
| vibe | vibe-lms.sh, vibe-mlx.sh, vibe-ollama.sh, vibe-omlx.sh | vibe.sh |
| qwen | qwen-omlx.sh | qwen.sh |

**Total: ~22 new consolidated adapter files, removing ~36 runtime-specific files.**

How each new adapter works:
- Sources `config.sh` to get `LITELLM_BASE_URL` and `LITELLM_PORT`.
- Sets the appropriate environment variable for the agent:
  - LM Studio clients: `--openai-api-base "$LITELLM_BASE_URL"` + `--openai-api-key ""`
  - oMLX clients: `--openai-api-base "$LITELLM_BASE_URL"` + `--model "omlx/<id>"`
  - OpenHands: `LLM_BASE_URL="$LITELLM_BASE_URL"` + `LLM_MODEL="openai/<id>"`
  - etc.
- The proxy routes based on the model ID prefix (`lms/`, `ollama/`, `omlx/`, etc.).

### 3. `bin/build-llmrun` — Remove --runtime flag

Current state: Generates a standalone `llmrun` with `--runtime` flag and per-runtime
model discovery.

Changes:
- Remove `--runtime` from the usage line.
- Remove all per-runtime `*_up()` health checks.
- Replace runtime-specific model discovery with a single `proxy_models()` that
  queries the proxy's `/v1/models` endpoint.
- Remove runtime-specific `cmd_runtime_start/stop/logs` (keep them but mark as
  "internal — the proxy handles routing").
- The adapter resolution always looks for `${TOOL}.sh` (no runtime suffix).
- The model is addressed through the proxy: `openai/<id>`, `lms/<id>`,
  `ollama/<id>`, `omlx/<id>`, `mtplx/<id>` depending on the model's origin.
- The proxy's `/v1/models` returns all models from all backends, prefixed by
  their route (e.g., `lms/ornith-1.0-9b`, `omlx/Ornith-1.0-35B-4bit`).

### 4. `bin/bench` — Default runtime to proxy

Current state: Default `RUNTIME="lms"`, with `--runtime` flag accepting
`lms | ollama | mlx | omlx | mtplx`.

Changes:
- Default `RUNTIME="litellm-proxy"` (or remove the flag entirely).
- Remove the `case "$RUNTIME"` block that maps to per-runtime URLs.
- Model discovery always queries `$LITELLM_BASE_URL`.
- The proxy's `/v1/models` returns all models with route prefixes.
- Adapter resolution always looks for `${TOOL}.sh` (no runtime suffix).

### 5. `bin/lib/model-profiles.sh` — Update alias resolution

Current state: Resolves aliases from `models-aliases.conf` which maps
`alias → lms_id, mlx_id, ollama_id, [omlx_id]` — runtime-specific IDs.

Changes:
- Add a new resolution mode: `alias_ids_proxy <alias>` that returns the
  proxy-compatible model ID (e.g., `lms/ornith-1.0-9b`).
- The `models-aliases.conf` format is already compatible — it maps aliases
  to per-runtime IDs. The proxy just needs the correct prefix.
- When using the proxy, the adapter selects the correct prefix based on the
  model's origin (which the alias file already encodes).

### 6. Tests — Update test files

Test files that need updating:
- `bin/build-llmrun.test.sh` — update expected output (no --runtime flag).
- `bin/check-model-discovery.test.sh` — update to use proxy model discovery.
- `bin/lib/agent-settings.test.sh` — update adapter path expectations.

## Files Changed (Summary)

| File | Change |
|------|--------|
| `config.sh` | Add proxy defaults, document proxy usage |
| `adapters/*.sh` | ~58 files: consolidate to ~22 unified adapters |
| `bin/build-llmrun` | Remove --runtime, use proxy for model discovery |
| `bin/bench` | Default to proxy, remove --runtime branching |
| `bin/lib/model-profiles.sh` | Add proxy-compatible alias resolution |
| `bin/build-llmrun.test.sh` | Update test expectations |
| `bin/check-model-discovery.test.sh` | Update test expectations |
| `bin/lib/agent-settings.test.sh` | Update test expectations |

## Implementation Order

1. **config.sh** — Add proxy defaults (foundation for everything else).
2. **One new consolidated adapter** (e.g., `pi.sh`) — validate the pattern.
3. **bin/build-llmrun** — Update the template to generate proxy-only llmrun.
4. **bin/bench** — Update to default to proxy.
5. **Remaining consolidated adapters** — Rewrite all ~22 agents.
6. **Tests** — Update all test files.
7. **Cleanup** — Remove old runtime-specific adapter files.

## Risks

- **Proxy must be running**: The proxy is a new dependency. If it's down, all
  adapters fail. Currently, adapters fail individually per runtime. This is a
  single point of failure. Mitigation: adapters could fall back to direct
  runtime if the proxy is unreachable (with a warning).
- **Model ID format changes**: Currently, each runtime uses its own model ID
  format (e.g., `lmstudio/ornith-1.0-9b` vs `omlx/Ornith-1.0-35B-4bit`).
  Through the proxy, these prefixes become `lms/` and `omlx/`. The proxy
  handles this routing internally. Adapters must generate the correct prefix.
- **Existing scripts/configs**: Any external scripts or CI configs that call
  `bin/bench --runtime ollama` will break. This is a breaking change.

## Backwards Compatibility

- The old runtime-specific adapter files (`<agent>-<runtime>.sh`) can be kept
  as symlinks to the new unified adapters, mapping the runtime suffix to the
  correct model prefix. This allows gradual migration.
- The `--runtime` flag can be kept in `bin/bench` but mapped to the appropriate
  model prefix for the proxy.
