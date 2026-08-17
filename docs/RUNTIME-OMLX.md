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

`bin/rt litellm proxy` exposes oMLX as `omlx/<id>` alongside the other runtimes, and
because oMLX is multi-model the route actually enumerates:

```bash
bin/rt litellm models | grep '^omlx/'
```

Native tool-calling works over that path (verified with a function-calling
request that came back with a structured `tool_calls` entry, not text).

## Unsupported quant: NVFP4 (compressed-tensors)

`Qwen3.8-27B-NVFP4` (`unsloth/Qwen3.8-27B-NVFP4`) fails to load on oMLX with a
409 ("VLM load failed: Received 937 parameters not in model") listing
`weight_scale`, `weight_packed`, `input_global_scale`, `weight_global_scale`
tensors. This is not a version bug to retry later — the checkpoint's
`quantization_config` (`quant_method: compressed-tensors`, mixed FP8/NVFP4
`config_groups`, `weight_packed` + per-tensor-group scales) is the vLLM /
llm-compressor NVFP4 export format, aimed at NVIDIA Blackwell hardware. MLX has
no loader for that tensor layout: mlx-lm's own NVFP4 support
([ml-explore/mlx-lm#717](https://github.com/ml-explore/mlx-lm/issues/717)) is
still an open feature request as of 2026-08, and even MLX-native NVFP4 quants
(e.g. `mlx-community/Qwen3.5-397B-A17B-nvfp4`) use MLX's own `mx.quantize`
tensor names, not compressed-tensors' `weight_packed`/`*_scale` naming — so an
mlx-lm/oMLX update alone will not fix this specific checkpoint.

Practical implication: this quant format needs a runtime with NVFP4/blockwise
FP4 kernels (e.g. vLLM on Blackwell), not oMLX. If an MLX-native NVFP4 (or
just re-quantized 4-bit MLX) build of this model appears on `mlx-community`,
that would load fine — but the `unsloth/Qwen3.8-27B-NVFP4` repo as published
is out of scope for this runtime. Documented as unsupported rather than
retested per release.

## Dense models are the wrong shape for oMLX-under-timeout

Benched 2026-08-15: `Qwen3.8-27B-4bit` (dense, all ~27B params active every
token) runs at only ~8 tok/s on oMLX, vs ~30+ tok/s for the MoE entries above
(`Qwen3.6-35B-A3B-MLX-4bit`, `Ornith-1.0-35B-4bit` — 256 experts, 8 active).
That's architectural, not a bug: MoE models spend compute on a handful of
experts per token regardless of total size, dense models spend it on
everything. At 8 tok/s the harder cases (`bash-01-topwords`,
`deleg-01-validate-format-pipeline`, `ts-01-groupby`) blow through the 300s
timeout / 120s stall watchdog across every adapter:

| runtime/model | pass rate | avg s |
|---|---|---|
| ollama `qwen3.8:27b-mlx` | 90.9% (160/176) | 111.5s |
| omlx `Qwen3.8-27B-4bit-mlxc` | 81.0% (136/168) | 163.7s |
| omlx `Qwen3.8-27B-4bit` (Qwen org) | 70.3% (121/172) | 173.5s |

Ollama's own MLX backend is simply faster for this dense model than oMLX is —
**prefer the ollama tag for any dense 27B+ model**; reserve oMLX for MoE
models or smaller dense ones where the timeout budget isn't the bottleneck.
The two omlx entries above are the *same weights/quant family* re-uploaded by
two orgs — the gap between them is a single-trial result and may just be
run-to-run variance, not a real quality difference between the uploads.

## Gotcha

oMLX will happily serve a model whose config doesn't match its weights and only
fail at load time. The `KAT-Coder-V2.5-Dev` note in the opencode config (VLM
config over text-only weights, "Missing 333 parameters") no longer reproduces on
oMLX 0.5.7 — it loads and answers — so treat such notes as version-stamped.

## Gotcha: model id is the basename only, org is invisible

The model id oMLX exposes is *only* the directory basename — the `<org>` path
segment in `$OMLX_MODELS_DIR/<org>/<name>` is never part of the id. Two
different repos re-uploading the same weights under the same folder name
collide silently: whichever oMLX happens to index shadows the other, with no
error. Hit this 2026-08-15 with `Qwen/Qwen3.8-27B-4bit` and
`mlx-community/Qwen3.8-27B-4bit` both resolving to id `Qwen3.8-27B-4bit` —
only one was ever reachable. Fixed by renaming the mlx-community copy's
directory to `Qwen3.8-27B-4bit-mlxc` so both are addressable. When adding a
model whose basename might already exist, check `bin/omlx models` first, and
if it collides, give the new copy a disambiguating suffix before `bin/omlx
reload`.
