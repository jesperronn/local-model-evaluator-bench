# Setup — LM Studio, CLIs, and editor extensions

Related: [README](../README.md) · [CASES.md](CASES.md) · [SCORING.md](SCORING.md) · [ADDING-CASES.md](ADDING-CASES.md)


Everything points at one endpoint: LM Studio's OpenAI-compatible server,
default `http://localhost:1234/v1`. Configure it once in `config.sh`.

## 1. LM Studio

```bash
lms server start            # start the OpenAI-compatible server on :1234
lms ls                      # list downloaded models + their ids
lms load <model-id>         # load a model into memory (or load it in the GUI)
lms ps                      # show what's currently loaded
```

> **Running headless (no GUI).** LM Studio can be operated entirely via the
> `lms` CLI (binary at `~/.lmstudio/bin/lms`) — the GUI app is not required for
> any of the above. Model management uses the CLI too; `lms` has no `rm`
> command, so deletion goes through [`bin/prune`](#bin-prune-model-disk-cleanup)
> (or manually removing dirs under `~/.lmstudio/models/`).
>
> **Storage layout:** the real model weights live at
> `~/.lmstudio/models/lmstudio-community/<HF-dir>/`. `~/.lmstudio/hub/models/<pub>/<key>/`
> holds tiny (KB-sized) pointer dirs only — not the weights. The authoritative
> modelKey → concrete-dir mapping is
> `~/.lmstudio/.internal/model-index-cache.json`
> (`concreteModelDirAbsolutePath`) — use that instead of guessing from
> filenames. ("llmster" is LM Studio's internal codename, seen under
> `~/.lmstudio/.internal/llmster-*` — not a separate product.)

`bin/doctor` calls the server's `/v1/models` and prints the **loaded** model ids
— those are the strings the clients must use.

> **Model id caveat.** Most tools address a model by the id LM Studio exposes on
> `/v1/models`, which usually matches `lms ls`. If a tool can't find a model,
> run `bin/doctor`, copy the exact id it prints, and use that in `models.txt`.

> **One model at a time.** Local inference is memory-bound. `bin/bench` does not
> load/unload models for you — load the one you're testing (or test models in
> separate runs). You can automate loading with `lms load`/`lms unload` around
> a `--models <one-id>` run if you want a fully unattended sweep.

### Context length & concurrency — persistent defaults

Two load-time settings matter for real use, especially when **editor extensions
or several agents hit the server at once**: a large enough **context window**,
and **`--parallel`** (how many predictions one loaded model serves
concurrently — without it, concurrent requests queue).

`lms load` takes both as flags, but they are **per-invocation, not global**:

```bash
lms load <id> --context-length 65536 --parallel 4 --ttl 3600 --yes
```

There is no CLI flag for a persistent default. The two persistence layers LM
Studio actually has:

| Lever | Where | Scope | Caveat |
|-------|-------|-------|--------|
| **Global default context** | GUI → Settings → *Default Context Length* (persists to `~/.lmstudio/settings.json` → `defaultContextLength`) | every JIT-loaded model | App-managed JSON — set via GUI, not by hand (the app rewrites it). A blanket-high default costs KV-cache RAM on **every** load — fine on 128 GB, risky on 32 GB. |
| **Per-model default load config** | GUI → My Models → model ⚙ → set load config → *set as default* | one model's JIT loads | Can pin both context **and** `--parallel`. Stored in `~/.lmstudio/.internal/user-concrete-model-default-config/<model>.json` (app-managed). |
| **`--parallel`** | `lms load` flag **only** | that load | No global default exists at all. |

> **Editor extensions bypass `lms load`.** Cline/Continue/etc. hit the OpenAI
> endpoint, and with **JIT loading on** (`justInTimeModelLoading: true`, the
> default) LM Studio auto-loads the model on first request — using the *default*
> load config above, **not** any CLI flag. So the reliable way to guarantee an
> extension gets high context + concurrency is to **pre-load explicitly** before
> opening the editor; an already-loaded instance is reused (JIT only fires if
> nothing is loaded). A dotfiles `lms-serve` wrapper makes this one command —
> see `source/91_ai_tools.sh` in the dotfiles repo.

## 1b. hf CLI (required for model updates)

`bin/lms_update` uses `hf` to re-download stale models directly from
HuggingFace, bypassing `lms get` which can hang on XetHub-backed repos.

```bash
brew install hf
hf --version    # verify
```

`bin/doctor` checks for it and prints an install hint if missing.

## 2. Adding a model under test

1. Download it in LM Studio (GUI) or `lms get <id>`.
2. Add its id as a new line in `models.txt`.
3. `bin/doctor` to confirm the id resolves; `bin/bench --models <id>` to test it.

**Shortcut:** run `bin/scout` any time after downloading — it diffs `lms
ls`/`ollama list` against `models.txt`/`models-ollama.txt` and prints a
ready-to-run command for anything new:

```
NOTE: new model not registered globally: qwen/qwen3.5-9b (lms)
   bin/sync --provider lms --model qwen/qwen3.5-9b --agent pi
```

`bin/sync` does steps 2–3 for you (plus seeding `~/.config/llmrun/agents.json`
with recommended settings) and runs `bin/smoke` to prove the model actually
works with the adapter(s) you list. It's read-only for the *other* direction
too: a model that's registered but no longer downloaded is flagged, never
auto-removed — use [`bin/prune`](#bin-prune-model-disk-cleanup) for that.

> **Why `models.txt` still exists even though some CLIs auto-discover
> models.** A few adapters (goose, cn, cline — see the table above) can list
> whatever's installed on a backend. That doesn't replace `models.txt`:
> discovery answers "what's installed," while `models.txt` is this repo's
> curated **rotation** — which of the installed models the nightly bench
> actually runs, in what order, with commentary on why others were dropped
> (see the comments in the file itself). The bench also always pins one
> explicit model id per trial for reproducible scoring, so no adapter's
> discovery UI enters the loop during a run. On a fresh machine, `models.txt`
> is also the fastest way to know *what to download* before anything is
> installed — discovery has nothing to show until then.

### Which model — modern-efficiency features

The harness rewards *smallest/fastest that still passes*, so prefer
architectures designed for fast local inference (these are co-equal with raw
benchmark scores when choosing what to download):

- **MLX** — Apple Silicon-native; generally faster than GGUF on Mac. Prefer the
  MLX build of a model when one exists.
- **MoE / A3B** — sparse Mixture-of-Experts that activate only a few billion
  params per token (e.g. `*-A3B` = ~3B active). Gives large-model quality at
  small-model token speed; the default for tight-VRAM, accuracy-sensitive work.
- **QAT** — quantization-aware-trained weights run quantized with little
  quality loss vs the full-precision model.
- **MTP** — multi-token prediction / speculative decoding, ~1.4–2× faster
  generation with no accuracy cost (dense models gain more than MoE). Use the
  MTP-converted build where offered.

### Which quantization — accuracy vs speed vs context

Quantization is the lever between accuracy and footprint. Two rules that matter
for this harness's **multi-file** and **self-verifying** cases:

- **Multi-file / patch-format work is quant-sensitive.** Reproducing exact file
  paths, identifiers, and diff formatting across a long context degrades *first*
  under aggressive quantization (dropped edits, wrong symbols, malformed
  patches) — well before chat quality drops. Don't judge a quant by chat feel.
- **MoE / A3B models are *more* quant-sensitive than dense ones** — fewer active
  weights carry each decision, so rounding error hits harder. Bump a bit-level
  for sparse models doing structured edits.

Rough guidance (MLX bit-levels):

| Quant | Use for |
|-------|---------|
| **4-bit** | Single-file edits, chat, max speed. Risky for A3B multi-file work. |
| **6-bit** | Sweet spot for accuracy-sensitive agentic editing — near-lossless, leaves RAM for a large context (which itself aids multi-file accuracy). |
| **8-bit** | Effectively lossless vs the original weights; max fidelity when RAM allows and you accept slower tokens + less context headroom. |

When in doubt, download two bit-levels and benchmark them head-to-head with
`bin/bench --models <id-a>,<id-b>` on a multi-file case — the harness measures
the real accuracy delta so you don't have to guess.

## 3. The CLI adapters

Each `adapters/<name>.sh` drives one CLI **non-interactively**, in the sandbox's
working directory, reading the task prompt from stdin, with `$MODEL_ID` set.
That's the whole contract — add a new CLI by writing one such script.

How each is pointed at LM Studio:

| CLI       | Model discovery / how it finds LM Studio                                            | Status |
|-----------|--------------------------------------------------------------------------------------|--------|
| `aider`   | Generic OpenAI provider: `--openai-api-base $LMS_BASE_URL` + `openai/<id>` model. **No runtime discovery** — user runs `ollama list`/`curl .../v1/models` and types the id by hand. | ✅ works |
| `opencode`| Built-in `lmstudio` provider (auto-discovers from `localhost:1234`); `lmstudio/<id>`.| ✅ works |
| `codex`   | Custom provider inline via `-c` (`lmstudio` is a RESERVED id → use `lmstudio_local`).| ✅ works |
| `caveman` / `pi` | `pi`-based (`@earendil-works/pi-coding-agent`); LM Studio provider defined in `~/.pi/agent/models.json`; `--provider lmstudio`. **No runtime discovery** — do not confuse with the unrelated [`oh-my-pi`](https://github.com/can1357/oh-my-pi), which does discover. `bin/agents-config` keeps this repo's `models.json` in sync with `lms ls`/`ollama list`. | ✅ works |
| `hermes`  | Built-in `lmstudio` provider (`~/.hermes/config.yaml`) + `-t file,terminal`.         | ⚠️ container-isolated |
| `goose`   | `GOOSE_MODEL` env var, pinned per bench trial. **Has runtime discovery** for standalone use — `goose configure` queries Ollama/`/v1/models` and populates a picker; not used by the bench adapter, which always sets `GOOSE_MODEL` explicitly. | ✅ works |
| `cn` (Continue CLI) | Per-run generated `config.yaml` with explicit `model: $MODEL_ID`. **Has runtime discovery** for standalone use — Continue's `model: AUTODETECT` scans the local Ollama install; the bench doesn't use `AUTODETECT` since it needs a specific model pinned. | ✅ works |
| `cline`   | VS Code extension settings, Model ID = id from `bin/doctor`. **Has runtime discovery** for standalone use — its built-in "LM Studio"/"Ollama" presets live-fetch the model list into the settings dropdown. | ✅ works |
| `nanocoder`| `NANOCODER_PROVIDERS` env var with an explicit `models` array. **No confirmed runtime discovery** — schema requires listing model ids up front; leans manual. | ✅ works |

> **`caveman` provider config** lives in `~/.pi/agent/models.json` (machine
> config — consider moving to dotfiles). A ready-to-copy template is committed
> at [`config-templates/pi-agent-models.json`](../config-templates/pi-agent-models.json):
> ```json
> { "providers": { "lmstudio": {
>     "baseUrl": "http://localhost:1234/v1", "api": "openai-completions",
>     "apiKey": "lm-studio", "models": [ { "id": "qwen/qwen3-coder-30b" } ] } } }
> ```
> Add each model id you test to that `models` array.

> ### Configuring `hermes` (no-yolo, fully local)
>
> hermes runs its tools in a sandbox that, by default (`backend: docker`), never
> surfaces edits to the host. The **recommended no-yolo setup** — used by the
> adapter and verified by `bin/doctor` — sets two keys in `~/.hermes/config.yaml`:
>
> ```yaml
> terminal:
>   backend: local          # tools run on the host so edits reach the sandbox
> approvals:
>   mode: smart             # LLM "guardian" approves safe ops, denies dangerous
>                           # ones, escalates uncertain (60s timeout -> deny)
> ```
>
> (These keys are also captured at
> [`config-templates/hermes-config.snippet.yaml`](../config-templates/hermes-config.snippet.yaml).)
>
> With `mode: smart` the adapter does **not** pass `--yolo`: every tool action is
> reviewed by the guardian (which uses the same local LM Studio model via
> `models.approval.provider: auto`), so execution is gated rather than blanket-
> approved. This is strictly safer than `local` + `--yolo` while still running
> non-interactively. Verified working: hermes edits the host sandbox and scores
> on the real cases. (The earlier `docker` + `docker_mount_cwd_to_workspace`
> attempt did not surface edits on macOS — `local` is the path that works.)
>
> ⚠️ Trade-off: `backend: local` executes the agent's tool calls on your host
> (not in a container). The `smart` guardian is the safety layer; review it if
> you run untrusted prompts. This config belongs in your dotfiles.

If `opencode`'s `lmstudio` provider needs a non-default URL, set it in
`~/.config/opencode/opencode.json`:

```json
{ "provider": { "lmstudio": { "options": { "baseURL": "http://localhost:1234/v1" } } } }
```

For a persistent `codex` setup instead of inline `-c`, add to `~/.codex/config.toml`:

```toml
[model_providers.lmstudio]
name = "LM Studio"
base_url = "http://localhost:1234/v1"
env_key = "LMS_API_KEY"
```

### `bin/prune` — model disk cleanup

Downloaded models pile up fast across `lms`/Ollama/MLX. `bin/prune` lists and
deletes them:

```bash
bin/prune --runtime=lms --unused   # models not referenced by any models*.txt/aliases
bin/prune -i                       # interactive fzf picker
bin/prune --dry-run                # preview only, no deletion
```

Flags: `--runtime=lms|ollama|mlx|all`, `--unused`, `--dry-run`. Listing is
always safe; deletion requires `-i` or an explicit target. For `lms`, model
resolution reads `~/.lmstudio/.internal/model-index-cache.json` for the
authoritative modelKey → concrete-dir mapping (no filename-guessing — an
earlier token heuristic mis-mapped `E4B` → `12B`). It deletes the concrete
weights dir plus any uniquely-owned hub pointer together, and skips index
entries whose dir no longer exists (the cache goes stale after deletes).
`--unused` falls back to token-subset matching so a not-yet-indexed download
still matches its id in the bench model lists.

## 4. Editor extensions (same LM Studio server)

The CLIs are the automated part. To evaluate the **VS Code / IntelliJ**
experience, point the extension at the same endpoint and run the same
`cases/<id>/` tasks by hand, then grade with the case's own grader:

```bash
# after editing a case's files inside the IDE, score them:
cd <your-edited-copy-of cases/<id>/workdir>
CASE_DIR=/abs/path/to/cases/<id> REPO_ROOT=/abs/path/to/repo \
  bash "$CASE_DIR/check/run.sh"        # prints RESULT pass=N total=N
```

Extension configuration:

- **VS Code — Cline / Roo**: pick the *OpenAI Compatible* provider, Base URL
  `http://localhost:1234/v1`, any API key, model id from `bin/doctor`.
- **VS Code — Continue**: add an `openai` provider in `config.json` with
  `"apiBase": "http://localhost:1234/v1"` and the model id.
- **JetBrains — Continue / ProxyAI (CodeGPT)**: choose a *Custom / LM Studio*
  or *OpenAI-compatible* service, Base URL `http://localhost:1234/v1`, model id.

LM Studio also advertises itself on the local network, so most "LM Studio"
presets in these extensions auto-discover loaded models without extra config.
