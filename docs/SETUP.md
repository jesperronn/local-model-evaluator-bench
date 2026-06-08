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

`bin/doctor` calls the server's `/v1/models` and prints the **loaded** model ids
— those are the strings the clients must use.

> **Model id caveat.** Most tools address a model by the id LM Studio exposes on
> `/v1/models`, which usually matches `lms ls`. If a tool can't find a model,
> run `bin/doctor`, copy the exact id it prints, and use that in `models.txt`.

> **One model at a time.** Local inference is memory-bound. `bin/bench` does not
> load/unload models for you — load the one you're testing (or test models in
> separate runs). You can automate loading with `lms load`/`lms unload` around
> a `--models <one-id>` run if you want a fully unattended sweep.

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
| `aider`   | Generic OpenAI provider: `--openai-api-base $LMS_BASE_URL` + `openai/<id>` model.    | ✅ works |
| `opencode`| Built-in `lmstudio` provider (auto-discovers from `localhost:1234`); `lmstudio/<id>`.| ✅ works |
| `codex`   | Custom provider inline via `-c` (`lmstudio` is a RESERVED id → use `lmstudio_local`).| ✅ works |
| `caveman` | `pi`-based; LM Studio provider defined in `~/.pi/agent/models.json`; `--provider lmstudio`.| ✅ works |
| `hermes`  | Built-in `lmstudio` provider (`~/.hermes/config.yaml`) + `-t file,terminal`.         | ⚠️ container-isolated |

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
