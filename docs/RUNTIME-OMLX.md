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
| port | 8080 | 8000 (oMLX's own default) |
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

Verified end to end 2026-08-08 on `Ornith-1.0-35B-4bit`, 3/3 smoke cases each
(see [docs/HANDOFF-omlx-adapters.md](HANDOFF-omlx-adapters.md) for the full
sweep):

- `adapters/cline-omlx.sh`, `adapters/hermes-omlx.sh`, `adapters/copilot-omlx.sh`,
  `adapters/codex-omlx.sh`, `adapters/caveman-omlx.sh`
- `adapters/openhands-omlx.sh`, `adapters/goose-omlx.sh`, `adapters/cn-omlx.sh`,
  `adapters/gptme-omlx.sh`, `adapters/nanocoder-omlx.sh`,
  `adapters/mini-swe-agent-omlx.sh`

Notable fixes made along the way (all pre-existing environment/adapter issues
that blocked these agents on *every* runtime, not just omlx):

- **hermes**: `~/.hermes/config.yaml` had drifted to `terminal.backend: docker`;
  reset to `local` per `config-templates/hermes-config.snippet.yaml`.
- **codex**: unlike `codex-mlx.sh` (a stub — mlx_lm.server wasn't reachable via
  codex's `--oss` path), oMLX gets the same custom-provider +
  `wire_api=responses` treatment as `codex-lms.sh`, since that constraint
  doesn't apply to a custom provider block.
- **caveman**: added an `omlx` provider block to `~/.cave/agent/models.json`
  and `config-templates/caveman-agent-models.json`, mirroring pi's — unlike
  `caveman-mlx.sh` (a stub, since mlx_lm.server's raw HF-repo ids can't be
  registered), oMLX's directory-basename ids work exactly like pi's.
- **nanocoder**: named the injected provider `"oMLX"` instead of reusing
  `nanocoder-lms.sh`'s `"LM Studio"` — a newer nanocoder rejects provider names
  containing a space (see [MODEL-DISCOVERY.md](MODEL-DISCOVERY.md)).
- **mini-swe-agent**: the global config at
  `~/Library/Application Support/mini-swe-agent/.env` was missing
  `MSWEA_CONFIGURED=true` and had a corrupted `MSWEA_MODEL_NAME` (an earlier
  non-interactive run's prompt answer got the task text appended to it),
  which made every invocation either hang on the first-run setup wizard or
  read a garbage default model. Fixed the `.env` directly. The adapter also
  needs `-c mini.yaml -c agent.mode=yolo` (default `agent.mode` is `confirm`,
  which hangs forever with piped stdin — omitting `-c mini.yaml` when
  overriding `agent.mode` drops the default config's required
  `system_template`/`instance_template` fields) and
  `MSWEA_COST_TRACKING=ignore_errors` (litellm has no cost table for local
  model ids).

Known non-omlx-specific limitations hit along the way:

- **copilot**: patch-format incompatibility documented in
  [AGENT-SELECTION.md](AGENT-SELECTION.md) shows up as an occasional flake
  (1 failure, passed 3/3 on immediate retry) — consistent with the existing
  lms/mlx notes, not an omlx regression.
- **claude**: consistently fails smoke-01/02 — the model narrates that it
  "doesn't have write permission" instead of calling the edit tool, even
  though `--allow-dangerously-skip-permissions --print --bare` is passed.
  Adapter wiring is confirmed correct (`all adapters reached the model`); this
  reads as a small-model tool-calling compliance gap, not a routing bug.
- **forge**: broken at the native-binding level
  (`Error: Could not locate the bindings file`) regardless of runtime —
  an npm/native-module install problem, unrelated to omlx.
- **interpreter**: genuinely blocked — see
  [docs/DECISION-interpreter-omlx.md](DECISION-interpreter-omlx.md).
- **omp**: deferred — currently can't even run `--help` on this machine
  (broken `bun` install); see
  [docs/DECISION-omp-omlx.md](DECISION-omp-omlx.md).

pi, opencode, and caveman all need an `omlx` provider block in their own
config — none of the three query `/v1/models`. `bin/agents-config` keeps the
model lists inside those blocks in sync, but deliberately will not create the
block itself.

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
