# How each agent discovers models

**Measured:** 2026-08-06, against oMLX (10 models) and LM Studio (11 models).

Every runtime here exposes `GET /v1/models`. Almost no agent uses it. That single
fact explains most "I added a model and the agent can't see it" friction, and it
is why `bin/agents-config` exists: the harness does the discovery the agents
don't, and writes the result into each agent's own config.

## Method

Not read from docs — measured. A recording reverse proxy sat between each
adapter and the runtime, logging every request path; each adapter was then run
with `LMS_BASE_URL` pointed at the recorder on a trivial prompt. A `GET
/v1/models` in the log means the agent discovers; only `POST
/v1/chat/completions` means it takes whatever model id it was handed. Agents
with their own model-list command were additionally checked against the live
inventory (`lms ls`, `ollama list`, `bin/omlx models`).

## Results

| Agent | Calls `/v1/models`? | How it decides what models exist | Consequence |
|---|---|---|---|
| **codex** | **yes** | queries the endpoint at startup (`GET /v1/models?client_version=…`) | add a model to any runtime, codex sees it. No config edit. |
| **goose** | **yes** | queries the endpoint before the first completion | same — nothing to maintain |
| **forge** | **yes** (Ollama API) | live `ollama list` equivalent, incl. embedding models | discovers, but only for its configured provider (ollama here) |
| **aider** | no | pure passthrough: whatever `--model` says | never "missing"; but unknown ids need `--model-metadata-file` or it refuses to run |
| **cline** | no | passthrough via `--baseurl`/`--modelid` | same as aider |
| **copilot** | no | passthrough via `COPILOT_PROVIDER_BASE_URL` | same |
| **gptme** | no | passthrough (`openai/<id>`) | same |
| **openhands** | no | passthrough (`LLM_MODEL=openai/<id>`) | same |
| **claude** | no | passthrough (Anthropic wire format, `/v1/messages`) | same |
| **cn** (Continue) | no | models enumerated in generated `config.yaml` | adapter regenerates the file per run, so it stays correct |
| **opencode** | **no** | config `provider.<name>.models` **merged with its built-in registry** | worst of both — see below |
| **pi** | no | `~/.pi/agent/models.json` provider catalog | unlisted model = "not found" even when served |
| **caveman** | no | `~/.cave/agent/models.json` (same schema as pi) | same |
| **hermes** | no | `providers.<name>.models` in `~/.hermes/config.yaml` | same, and currently **stale** — see below |
| **interpreter** | n/a | **hardcoded** built-in `lmstudio` provider at `localhost:1234` | ignores `LMS_BASE_URL` entirely; cannot target ollama/mlx/omlx |
| **nanocoder** | n/a | adapter is currently broken (see below) | untested |

## The opencode trap

opencode was the one that cost you manual edits, and it fails in *both*
directions at once:

- **Models you have don't appear.** `ornith-1.0-9b` is installed in LM Studio
  and served on `/v1/models`; opencode does not list it. Only what's in
  `provider.lmstudio.models` counts. (Here it's additionally excluded on
  purpose — `compat.json` marks ornith broken for opencode.)
- **Models you don't have do appear.** opencode's list included
  `lmstudio/openai/gpt-oss-20b` and `lmstudio/qwen/qwen3-30b-a3b-2507`, neither
  installed nor configured. Naming a provider `lmstudio` makes opencode merge
  its built-in registry entries for that provider id on top of your config.

So the list is neither your config nor the runtime — it's a union with a
registry you don't control. Providers with a name the registry doesn't know
(`omlx`) show config contents only, which is the predictable case.

Two more sharp edges found while testing:

- `OPENCODE_CONFIG` is **ignored** — pointing it at a modified copy produced a
  byte-identical model list. There is no way to A/B a config without editing the
  real file.
- There are two configs side by side: `~/.config/opencode/opencode.json` (stale,
  one model) and `opencode.jsonc` (current). `bin/agents-config` writes the
  `.jsonc`, which is the one opencode reads — but the leftover `.json` is a trap
  for anyone editing by hand.

## hermes is drifting

`~/.hermes/config.yaml` lists `ibm/granite-4.1-30b`, `google/gemma-4-26b-a4b`,
`qwen/qwen3.6-27b` under lmstudio — none installed. `bin/agents-config` treats
hermes as settings-only and opt-in (`--agent hermes`), so its model list is
hand-maintained and has rotted. Either extend the sync or expect hermes to name
models that no longer exist.

## What this means for adding a model

After `lms get` / `ollama pull` / dropping a directory in `~/.omlx/models`:

```bash
bin/omlx reload            # oMLX only: rescan the model dir
bin/agents-config --write  # push the new inventory into opencode/pi/caveman
```

codex, goose and forge need neither step. aider, cline, copilot, gptme,
openhands, claude and cn need nothing either — they never had a list to update.
Everything else needs the sync.

## Known breakage found during this pass

- **nanocoder adapter is broken**: `nanocoder --provider "LM Studio"` is
  rejected — "Provider name must contain only alphanumeric characters, hyphens,
  and underscores". A newer nanocoder tightened provider-name validation;
  `adapters/nanocoder-lms.sh` still passes the old display name.
- **interpreter cannot be pointed at a non-LM-Studio runtime.** It uses its
  built-in `lmstudio` provider (hardcoded `localhost:1234`), which is why there
  is no `interpreter-mlx.sh`. Any `--runtime` other than lms silently talks to LM
  Studio instead.
