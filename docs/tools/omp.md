# omp (oh-my-pi)

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | omp (oh-my-pi) — a pi fork, distinct tool despite the similar name (see [pi.md](pi.md)) |
| **CLI command** | `omp` |
| **Installation** | `brew install omp` (or npm: `npm install -g @oh-my-pi/pi-coding-agent`) |
| **Upstream** | [github.com/can1357/oh-my-pi](https://github.com/can1357/oh-my-pi) |
| **Adapter script** | [`adapters/omp.sh`](../../adapters/omp.sh) |
| **How it connects** | Routes ONLY through Olla (see [docs/runtimes/olla.md](../runtimes/olla.md) "Adapter wiring") — no more LiteLLM/direct-runtime branching. omp's `--config` overlay does **not** register a model-registry provider (confirmed empirically: `omp models --config <overlay>` doesn't pick up a new provider), so the adapter instead self-heals an isolated `--profile bench-olla`'s own `models.yml` with an `olla` provider (`discovery.type: openai-models-list`, so omp queries Olla's live `/models` itself) — this avoids ever touching the user's own `~/.omp/agent/models.yml`, which is commonly a dotfiles symlink. Model addressed as `--model "olla/<bare-id>"`. |
| **Runtime model discovery** | **yes** — via Olla's own `/models` discovery (`discovery.type: openai-models-list` in the profile's `models.yml`), not omp's own ollama/llama.cpp/lm-studio auto-registration. |
| **Config file** | `~/.omp/profiles/bench-olla/agent/models.yml` (bench-only, isolated profile) — **not** the user's own `~/.omp/agent/models.yml`. |
| **Last reviewed** | 2026-09-28 |
| **Recommended for** | not yet benchmarked |

## Edit mechanism

Not yet evaluated in this bench.

## Iteration / self-verify behaviour

Not yet evaluated in this bench.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--profile bench-olla` | Isolated agent state (auth/sessions/settings/caches, including `models.yml`) so the adapter's self-healed `olla` provider never touches the user's own `~/.omp/agent/models.yml` |
| `--model "olla/$BARE_MODEL_ID"` | Selects the model through the self-healed `olla` provider |

## Known issues

**`omp --help` fails with `Error: Bun's postinstall script was not run`.** This can occur with npm installations when the `bun` runtime's postinstall script doesn't run (e.g., with `--ignore-scripts` or package managers like pnpm). The brew installation handles this automatically. For npm installs, run the bun postinstall manually:

```bash
node "$(npm root -g)/@oh-my-pi/pi-coding-agent/node_modules/bun/install.js"
```

**`--config` does not register a model-registry provider.** Confirmed empirically (2026-09-28): `omp models --config <overlay-with-a-new-provider>` still only lists the providers already present in the active profile's `models.yml` — `--config` only overlays `config.yml`-style *settings* for the run, not the provider registry. Provider discovery only happens through `models.yml` itself; see the Olla routing above for how this adapter now works around that.

## Status

**stable (Olla-routed)** — migrated to route exclusively through Olla 2026-09-28 (see [docs/runtimes/olla.md](../runtimes/olla.md)); `bin/smoke -m omlx/Ornith-1.5-9B-MLX-4bit -a omp --skip-compat-update` → 2/3 PASS, 1/3 PARTIAL (smoke-02-numbers off-by-formatting, not a wiring issue), confirmed in Olla's own log (`user_agent":"omp/18.4.2"`).
