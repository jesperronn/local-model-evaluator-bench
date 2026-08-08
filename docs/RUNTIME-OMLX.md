# The `omlx` runtime (oMLX)

[oMLX](https://omlx.app) is a multi-model MLX server for Apple Silicon. It is the
fourth runtime alongside `lms`, `ollama` and `mlx`.

## Why it is separate from `mlx`

They are different servers with different operating models, and mixing them
would make old results uncomparable:

| | `mlx` (mlx_lm.server) | `omlx` (oMLX) |
|---|---|---|
| models per process | one | all of them, LRU-swapped |
| switching model | restart the server | just ask for it |
| port | 8080 | 4000 (oMLX's own default) |
| model id | HF repo or filesystem path | directory basename, e.g. `Ornith-1.0-9B-4bit` |
| `/v1/models` | the single loaded model | full inventory |

Operationally oMLX behaves like LM Studio or Ollama: no manual start/stop per
model, and real discovery.

## Everyday use

```bash
bin/omlx status                      # up? which models served / resident
bin/omlx models                      # the ids --runtime omlx accepts
bin/bench --runtime omlx --model Ornith-1.0-9B-4bit --agent aider
bin/smoke --runtime omlx --model Ornith-1.0-9B-4bit
```

`bin/rt` shows an oMLX row with served vs resident counts; `bin/rt stop omlx`
evicts every resident model and then stops the server.

## Adding a model

1. Put it at `$OMLX_MODELS_DIR/<org>/<name>` (default `~/.omlx/models`).
2. `bin/omlx reload` — oMLX discovers at startup, so a new directory needs a
   rescan.
3. `bin/omlx aider-metadata` — regenerates
   `adapters/aider-omlx-model-metadata.json`; aider refuses to run against a
   model id its registry doesn't know.
4. `bin/agents-config --write` — pushes the new inventory into the agents that
   can't discover (see [MODEL-DISCOVERY.md](MODEL-DISCOVERY.md)).
5. Optionally add the basename to `models-omlx.txt` so a bare
   `bin/bench --runtime omlx` includes it.

## Adapters

Verified end to end 2026-08-06 on `Ornith-1.0-9B-4bit`, 3/3 smoke cases each:

- `adapters/aider.sh` (unified; branches on `$RUNTIME`)
- `adapters/pi-omlx.sh`
- `adapters/opencode-omlx.sh`

pi and opencode both need an `omlx` provider block in their own config — neither
queries `/v1/models`. `bin/agents-config` keeps the model lists inside those
blocks in sync, but deliberately will not create the block itself.

Note for aider: do **not** force `--edit-format diff` here the way the ollama
branch does. Measured on Ornith-1.0-9B-4bit, it broke create-from-scratch (the
model emits a bare fenced block instead of a SEARCH/REPLACE pair with an empty
SEARCH). aider's default `whole` passes all three smoke cases.

## Cross-runtime comparisons

`models-aliases.conf` has a fifth column for the omlx id. Only fill it in when
the weights *and quant* match the other columns — otherwise a "runtime
comparison" is really measuring the quant. Currently mapped: `qwen3.6-35b-a3b`,
`qwen3-coder-30b`, `gpt-oss-20b`. Deliberately unmapped: `qwen3-coder-next`
(oMLX copy is 4-bit, lms/mlx copies are 6-bit).

## Through the LiteLLM proxy

`bin/litellm-proxy` exposes oMLX as `omlx/<id>` alongside the other runtimes, and
because oMLX is multi-model the route actually enumerates:

```bash
bin/litellm-proxy --models | grep '^omlx/'
```

Native tool-calling works over that path (verified with a function-calling
request that came back with a structured `tool_calls` entry, not text).

## Gotcha

oMLX will happily serve a model whose config doesn't match its weights and only
fail at load time. The `KAT-Coder-V2.5-Dev` note in the opencode config (VLM
config over text-only weights, "Missing 333 parameters") no longer reproduces on
oMLX 0.5.7 — it loads and answers — so treat such notes as version-stamped.
