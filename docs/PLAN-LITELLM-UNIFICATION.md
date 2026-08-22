# Plan: Unify All Adapters to Use LiteLLM Proxy, Remove --runtime Flag

## Context

Today, adapters choose between 5 local runtimes (lms, ollama, mlx, omlx, mtplx) via the `--runtime` flag in `bin/bench` and `llmrun`. Each runtime has its own base URL and API key, and adapters either have runtime-specific files (e.g., `cline-ollama.sh`) or branch on the `$RUNTIME` variable at runtime.

The goal is to consolidate on **LiteLLM proxy as the single endpoint** for all runtimes. This eliminates the `--runtime` flag entirely—adapters always talk to the proxy, which routes requests to the underlying runtime based on model name prefix (e.g., `lms/qwen2.5-coder-7b`, `ollama/neural-chat-7b`).

**Why:** Simpler user experience (no runtime selection), unified configuration, easier to add new runtimes, and auto-discovery of models across all backends from a single endpoint.

**Constraint:** Keep auto-discovery of models on startup so `llmrun` and `bin/bench --interactive` still work without manual model listing.

---

## Implementation Strategy

### Phase 1: Update Adapters (58 files)

**Goal:** All adapters talk to `$LITELLM_BASE_URL` instead of runtime-specific URLs.

#### 1.1 Unified Adapters (`adapters/<tool>.sh`)

Currently, some adapters branch on `$RUNTIME`. Examples: `aider.sh`, `cline.sh`, `claude.sh`, `opencode.sh`, `pi.sh`.

**Action:**
- Remove `$RUNTIME` branching (they no longer need to change API URLs or flags per runtime).
- Replace all references to `LMS_BASE_URL`, `OLLAMA_BASE_URL`, `MLX_BASE_URL`, `OMLX_BASE_URL`, `MTPLX_BASE_URL` with `$LITELLM_BASE_URL`.
- Keep tool-specific logic (e.g., aider's `--model-settings-file`, omp's config-file handling) — those don't change.

**Files affected:** Any unified adapter that currently sources `config.sh` or references runtime-specific URLs.

#### 1.2 Runtime-Specific Adapters (e.g., `adapters/cline-lms.sh`, `cline-ollama.sh`)

These files exist to handle runtime-specific quirks (e.g., lms needs explicit model loads; ollama/mtplx are multi-model; mlx is single-model).

**Action:**
- Delete all `-lms`, `-ollama`, `-mlx`, `-omlx`, `-mtplx` variant files.
- Move any essential logic into the unified adapter (e.g., if lms needs special handling, add it to `cline.sh` with a conditional on detected runtime or model prefix).
- All adapters now point to `$LITELLM_BASE_URL`.

**Rationale:** The proxy abstracts these differences. An adapter calls the same endpoint whether the backend is lms or ollama; the proxy routing (via model prefix) ensures it reaches the right runtime.

#### 1.3 Model Addressing in Adapters

Adapters must prefix model names with the runtime when calling the proxy. For example:
- User: `bin/bench --agent cline --model qwen2.5-coder-7b`
- Adapter receives `MODEL_ID=qwen2.5-coder-7b`
- Adapter calls: `curl $LITELLM_BASE_URL/chat/completions -d '{"model":"lms/qwen2.5-coder-7b",...}'` (or `ollama/qwen2.5-coder-7b` if it's from Ollama)

**Decision:** Where does the prefix come from?
- **Option A:** Adapters auto-detect: probe the proxy's `/v1/models` to find which runtime has the model, then prefix accordingly.
- **Option B:** `bin/bench` and `llmrun` pass `$RUNTIME_PREFIX` (e.g., "lms", "ollama") explicitly, and adapters use it.
- **Option C:** User specifies full prefixed model: `--model lms/qwen2.5-coder-7b` (no discovery).

**Recommendation:** Use **Option B** for now. `bin/bench` remains responsible for model discovery, but instead of selecting a runtime, it picks the first available model and exports `RUNTIME_PREFIX` to indicate its backend. Adapters use `"${RUNTIME_PREFIX}/${MODEL_ID}"` when calling the API. This keeps discovery centralized and adapters stateless.

---

### Phase 2: Update bin/bench

**Goal:** Remove `--runtime` flag; keep model discovery working.

#### 2.1 Remove --runtime Flag

**Location:** `bin/bench` lines 45–58, 178, 212–219, 244, 327–340.

**Action:**
1. Delete the `--runtime` flag documentation (line 45–58).
2. Remove `--runtime` from the case statement (line 178).
3. Delete the runtime validation case statement (line 327–340).
4. Hardcode discovery to use `$LITELLM_BASE_URL`.

#### 2.2 Update Model Discovery

**Current logic:**
```bash
case "$RUNTIME" in
  lms)    _base_url="$LMS_BASE_URL";;
  ollama) _base_url="http://localhost:11434/v1";;
  ...
esac
runtime_models "$_base_url"
```

**New logic:**
```bash
# Always discover from the proxy
runtime_models "$LITELLM_BASE_URL"
```

**Location:** `bin/bench` lines 211–230.

The proxy's `/v1/models` already returns models from all 5 backends, prefixed with their runtime (e.g., `lms/qwen2.5-coder-7b`, `ollama/neural-chat-7b`).

#### 2.3 Extract Runtime Prefix from First Selected Model

After discovery, extract the prefix from the first selected model and export it as `RUNTIME_PREFIX`:

```bash
# From MODEL_ARR[0], extract prefix (e.g., "lms" from "lms/qwen2.5-coder-7b")
RUNTIME_PREFIX="${MODEL_ARR[0]%%/*}"
export RUNTIME_PREFIX
```

This tells adapters which runtime was used, in case they need special handling (e.g., mlx is single-model).

#### 2.4 Update Interactive Mode

**Current:** Line 244 shows `bin/bench --runtime $RUNTIME --agent ...`

**New:** Show `bin/bench --agent ... --model ...` (no runtime).

#### 2.5 Remove Adapter Resolution per Runtime

**Current:** Lines 255–256 check for `<tool>-<runtime>.sh` first, then fall back to `<tool>.sh`.

**New:** Directly use `<tool>.sh` (the runtime-specific variants no longer exist).

#### 2.6 Update Health Check

**Current:** Line 384 checks `lms_up` for lms runtime, probes `/v1/models` for others.

**New:** Always probe `$LITELLM_BASE_URL/health/readiness` (or `/v1/models`) to verify the proxy is up.

---

### Phase 3: Update bin/build-llmrun and Generated llmrun Script

**Goal:** Remove `--runtime` flag from `llmrun` subcommand.

#### 3.1 Remove --runtime from Template

**Location:** `bin/build-llmrun` lines ~46 (template definition).

Replace:
```bash
llmrun [--agent <name>] [--runtime <type>] [--model <id>]
```

With:
```bash
llmrun [--agent <name>] [--model <id>]
```

#### 3.2 Update Generated Script

In the template embedded in `bin/build-llmrun`:
1. Remove `--runtime` from option parsing.
2. Remove the runtime case statement that sets BASE_URL.
3. Hardcode discovery to use `$LITELLM_BASE_URL`.
4. Extract `RUNTIME_PREFIX` from the first selected model.
5. Update adapter resolution to not check for `-<runtime>.sh` variants.

#### 3.3 Update Subcommands

`llmrun runtime start` should start **all** 5 runtimes (or a reasonable subset like lms/ollama/omlx), not just one. Alternatively, make it a no-op with a note: "all runtimes start automatically on llmrun agent/model selection."

`llmrun model list` should list all models from all backends (already does via proxy).

---

### Phase 4: Update Startup Script (llmrun, etc.)

**Goal:** Ensure lite-llm-proxy is started automatically when needed.

#### 4.1 Modify bin/build-llmrun or llmrun Preamble

When generating `llmrun`, ensure its startup checks:
1. All 5 local runtimes are running (or at least the ones needed for models used).
2. Lite-llm-proxy is running.
3. Model discovery returns results.

**Example flow:**
```bash
# Ensure runtimes are up (lms, ollama, omlx, mtplx, mlx)
bin/rt status  # Check what's running
if ! bin/litellm-proxy status; then
  info "Starting litellm-proxy..."
  bin/litellm-proxy start
fi
```

#### 4.2 Update bin/rt

Add a convenience command:
```bash
bin/rt all start  # Start all 5 runtimes + litellm-proxy
bin/rt all stop   # Stop all 5 runtimes + litellm-proxy
```

---

### Phase 5: Add Model Discovery/List Command to llmrun

**Goal:** Provide a convenient way to list all available models in litellm format (with runtime prefix).

#### 5.1 Add `llmrun model list` Command

**New subcommand in generated llmrun:**
```bash
llmrun model list [--json]
```

**Behavior:**
- Query `$LITELLM_BASE_URL/v1/models`
- List each model with its runtime prefix (e.g., `lms/qwen2.5-coder-7b`, `ollama/neural-chat-7b`)
- One model per line, sorted by runtime prefix, then by model name
- `--json` flag returns raw JSON response from the proxy (for tooling)

**Example output:**
```
lms/qwen2.5-coder-7b
lms/codestral-22b
mlx/openhermes-2.5-7b
mtplx/mistral-7b
ollama/neural-chat-7b
omlx/Ornith-1.0-9B-4bit
```

**Location:** Implement in the `llmrun` template in `bin/build-llmrun`, around lines where other model subcommands are defined.

**Implementation:**
```bash
cmd_model_list() {
  local json_flag="${1:-}"
  if [ "$json_flag" = "--json" ]; then
    curl -fsS "$LITELLM_BASE_URL/v1/models" 2>/dev/null
  else
    curl -fsS "$LITELLM_BASE_URL/v1/models" 2>/dev/null \
      | jq -r '.data[].id' 2>/dev/null | sort \
      || echo "Error: unable to reach proxy at $LITELLM_BASE_URL"
  fi
}
```

---

### Phase 6: Update config.sh and Model Discovery

**Goal:** Ensure model discovery uses the proxy, and prefixes are available to scripts.

#### 6.1 Update runtime_models() in lib/common.sh

**Current:**
```bash
runtime_models() {
  local base_url="$1"
  curl ... "$base_url/models"
}
```

**New:** No changes needed—the function already works with `$LITELLM_BASE_URL`. The proxy's `/v1/models` endpoint returns all models prefixed with runtime.

#### 6.2 Add Helper to Extract Runtime Prefix

In `lib/common.sh`, add a function:
```bash
extract_runtime_prefix() {
  local model="$1"
  echo "${model%%/*}"  # Extract prefix before the first /
}
```

Use this in `bin/bench` and `llmrun` after selecting a model.

---

### Phase 7: Update Documentation

#### 7.1 docs/MODEL-DISCOVERY.md

Update to reflect that discovery always happens via lite-llm-proxy, and model names are prefixed with runtime (e.g., `lms/qwen`, `ollama/neural-chat`).

#### 7.2 docs/AGENT-SELECTION.md

Remove any mention of `--runtime` flag; focus on adapter capabilities instead.

#### 7.3 README, etc.

Search for `--runtime` references and update.

#### 7.4 Add docs/LITELLM-UNIFICATION.md

New doc explaining the unified litellm-proxy model addressing:
- How model prefixes work (e.g., `lms/qwen2.5-coder-7b`)
- How to list all available models: `llmrun model list`
- How to target a specific runtime: use the prefix in `--model`
- How to run without specifying runtime: just use model name, discovery will auto-prefix

---

## Critical Files to Modify

### Definitely Changed
- **bin/bench** — Remove --runtime, update discovery, export RUNTIME_PREFIX
- **bin/build-llmrun** — Remove --runtime from template, update generated script
- **adapters/*.sh** — Replace all runtime-specific URLs with `$LITELLM_BASE_URL`, remove `$RUNTIME` branches (58 files total)
- **lib/common.sh** — Add `extract_runtime_prefix()` helper
- **config.sh** — Document that LITELLM_BASE_URL is now the primary endpoint

### Possibly Changed
- **bin/rt** — Add `all start/stop` convenience commands
- **bin/litellm-proxy** — Add auto-startup hook in llmrun
- **docs/** — Update model discovery, agent selection, and usage examples

### Deleted
- All `adapters/*-lms.sh`, `adapters/*-ollama.sh`, `adapters/*-mlx.sh`, `adapters/*-omlx.sh`, `adapters/*-mtplx.sh` files (the unified versions replace them)

---

## Model Name Addressing Strategy

### Current Behavior
- User: `bin/bench --agent cline --runtime ollama --model neural-chat-7b`
- Adapter gets `MODEL_ID=neural-chat-7b`, talks to `http://localhost:11434/v1`

### New Behavior
- User: `bin/bench --agent cline --model neural-chat-7b` (or interactively picks `ollama/neural-chat-7b`)
- `bin/bench` discovers model, extracts prefix `ollama`
- Adapter gets `MODEL_ID=ollama/neural-chat-7b` (or `MODEL_ID=neural-chat-7b` + `RUNTIME_PREFIX=ollama`)
- Adapter talks to `$LITELLM_BASE_URL/chat/completions` with `{"model":"ollama/neural-chat-7b"}`

**Decision:** Export both `MODEL_ID` (prefixed, e.g., `ollama/neural-chat-7b`) and `RUNTIME_PREFIX` (e.g., `ollama`) so adapters can use whichever is convenient.

---

## Verification

### 1. Smoke Test
```bash
bin/smoke --agent aider --models qwen2.5-coder-7b
```
Verify adapters can reach the proxy and execute a trivial task.

### 2. Interactive Mode
```bash
bin/bench --agent cline --interactive
```
Verify fzf picker works, discovers models from all 5 runtimes, and can run a case.

### 3. Direct Invocation
```bash
bin/bench --agent copilot --model ollama/neural-chat-7b --cases hello
```
Verify model prefix is respected and case runs.

### 4. llmrun
```bash
llmrun --agent opencode --interactive
```
Verify generated script discovers models and runs a case.

### 5. Model Listing
```bash
llmrun model list
```
Verify all models from all runtimes are listed with proper prefixes.

### 6. Model Aliases
If `models-aliases.conf` exists, test that aliases still resolve correctly (they should map to unprefixed model names, which `bin/bench` then prefixes based on where it finds them).

---

## Rollback Strategy

- **Before deletion:** Back up all removed adapter files (`*-lms.sh`, etc.) in a `backup/` directory.
- **If needed:** Copy them back and add runtime-specific logic to the unified adapters.
- **Git history:** All changes are incremental commits, so `git revert` works.

---

## Notes

1. **LiteLLM proxy must be running:** The startup script or `bin/bench` must ensure it's started. Consider making `bin/litellm-proxy start` idempotent so it can be called even if already running.

2. **Model prefixes in interactive mode:** The fzf picker will now show `ollama/neural-chat-7b` instead of just `neural-chat-7b`. This is clearer (shows which runtime), but adapters need to handle it.

3. **MTPLX and oMLX:** Both are multi-model, so their models will appear in the proxy's list with `mtplx/` and `omlx/` prefixes. The proxy config already handles this.

4. **MLX single-model limitation:** `mlx` is single-model per process; the proxy doesn't change that. If an adapter tries to use two different MLX models in sequence, the second will fail. This is a limitation of MLX, not the proxy, so it's acceptable.

5. **No cloud fallback:** The config already ensures no cloud fallbacks, so this refactoring doesn't change security or isolation.
