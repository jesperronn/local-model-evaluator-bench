# omp (oh-my-pi)

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | omp (oh-my-pi) — a pi fork, distinct tool despite the similar name (see [pi.md](pi.md)) |
| **CLI command** | `omp` |
| **Installation** | `brew install omp` (or npm: `npm install -g @oh-my-pi/pi-coding-agent`) |
| **Upstream** | [github.com/can1357/oh-my-pi](https://github.com/can1357/oh-my-pi) |
| **Adapter scripts** | [`adapters/omp-ollama.sh`](../../adapters/omp-ollama.sh), [`adapters/omp-omlx.sh`](../../adapters/omp-omlx.sh) |
| **How it connects (ollama)** | `--model "$MODEL_ID"` — omp auto-registers Ollama as a local provider and resolves the model directly. |
| **How it connects (omlx)** | omp has no built-in `omlx` provider. The adapter points omp's `lm-studio` provider at the oMLX server via `LM_STUDIO_BASE_URL="$OMLX_BASE_URL"`, then selects `--model "lm-studio/$MODEL_ID"`. Verified working live against a running oMLX server (`Ornith-1.0-35B-4bit`) — real inference output, not just theorized. See [DECISION-omp-omlx.md](../DECISION-omp-omlx.md). |
| **Runtime model discovery** | **yes** — omp auto-registers `ollama`, `llama.cpp`, and `lm-studio` as local providers and can enumerate their models (`omp models list`). This is the capability pi.md's metadata table calls out as absent from `@earendil-works/pi-coding-agent`. |
| **Config file** | `~/.omp/agent/models.yml` for custom provider config — **not** `models.json`, which is pi's format. Not yet investigated as a place to register a first-class `omlx` provider (see Known issues). |
| **Last reviewed** | 2026-08-11 |
| **Recommended for** | not yet benchmarked |

## Edit mechanism

Not yet evaluated in this bench.

## Iteration / self-verify behaviour

Not yet evaluated in this bench.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--model "$MODEL_ID"` (ollama) | Explicit model selection via omp's auto-registered Ollama provider |
| `LM_STUDIO_BASE_URL="$OMLX_BASE_URL"` (omlx) | Redirects omp's built-in `lm-studio` provider at the oMLX server, since omp has no native `omlx` provider |
| `--model "lm-studio/$MODEL_ID"` (omlx) | Selects the model through the redirected `lm-studio` provider |

## Known issues

**`omp --help` fails with `Error: Bun's postinstall script was not run`.** This can occur with npm installations when the `bun` runtime's postinstall script doesn't run (e.g., with `--ignore-scripts` or package managers like pnpm). The brew installation handles this automatically. For npm installs, run the bun postinstall manually:

```bash
node "$(npm root -g)/@oh-my-pi/pi-coding-agent/node_modules/bun/install.js"
```

**Config file is `~/.omp/agent/models.yml`, not pi's `models.json`.** omp reports this path as its custom-provider config file when a model lookup fails. Unlike pi, omp doesn't need this pre-populated for its auto-registered providers (ollama/llama.cpp/lm-studio), but it may be the right place to register a first-class `omlx` provider instead of routing through `lm-studio` — schema and viability not yet checked. See [DECISION-omp-omlx.md](../DECISION-omp-omlx.md) for the full history of the omlx routing workaround.

**No native `omlx` provider.** Confirmed by decompiling the installed `omp` binary (`dist/cli.js`, v17.2.12) — only `ollama`, `llama.cpp`, and `lm-studio` are auto-registered as local providers. The `lm-studio` provider redirect (above) is the current workaround.

## Status

**untested** — no benchmark runs recorded yet. `adapters/omp-ollama.sh` and `adapters/omp-omlx.sh` both exist; the omlx path has been smoke-tested for real inference output but not run through the full case suite.
