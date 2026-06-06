# Setup — LM Studio, CLIs, and editor extensions

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

## 2. Adding a model under test

1. Download it in LM Studio (GUI) or `lms get <id>`.
2. Add its id as a new line in `models.txt`.
3. `bin/doctor` to confirm the id resolves; `bin/bench --models <id>` to test it.

## 3. The CLI adapters

Each `adapters/<name>.sh` drives one CLI **non-interactively**, in the sandbox's
working directory, reading the task prompt from stdin, with `$MODEL_ID` set.
That's the whole contract — add a new CLI by writing one such script.

How each is pointed at LM Studio:

| CLI       | Model discovery / how it finds LM Studio                                            |
|-----------|--------------------------------------------------------------------------------------|
| `aider`   | Generic OpenAI provider: `--openai-api-base $LMS_BASE_URL` + `openai/<id>` model.    |
| `opencode`| Built-in `lmstudio` provider (auto-discovers from `localhost:1234`); `lmstudio/<id>`.|
| `codex`   | Custom `model_provider` passed inline via `-c` overrides → `base_url = $LMS_BASE_URL`.|
| `caveman` | OpenAI-compatible provider via `OPENAI_BASE_URL` env + `--provider openai`.          |
| `hermes`  | OpenAI-compatible provider via env + `--provider openai`.                            |

> **Verify before trusting.** The exact provider flags for `caveman` and
> `hermes` vary by version — the adapters carry a `NOTE:` line where to confirm
> (`caveman --help`, `hermes config`). If a model "isn't found", that adapter's
> flags are the first place to look. `aider`/`opencode`/`codex` syntax is stable.

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
