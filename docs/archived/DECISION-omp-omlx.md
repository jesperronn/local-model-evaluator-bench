# Decision: omp — omlx adapter deferred (broken install, unrelated to omlx)

**Date:** 2026-08-08
**Status:** Deferred — omp itself is non-functional on this machine right now

## Context

`omp` (`@oh-my-pi/pi-coding-agent`, a pi fork) currently only has
`adapters/omp-ollama.sh`, and it doesn't set any endpoint env var — unclear
whether it even supports pointing at an arbitrary OpenAI-compatible base URL
the way pi does via its own `models.json` provider blocks.

## Decision

Before that question could even be investigated, `omp --help` failed outright:

```
Error: Bun's postinstall script was not run.
This occurs when using --ignore-scripts during installation, or when using a
package manager like pnpm that does not run postinstall scripts by default.
```

`omp`'s CLI (installed via npm to `~/.npm-global/lib/node_modules/@oh-my-pi/pi-coding-agent/dist/cli.js`)
requires the `bun` runtime, whose own postinstall may not run. This is a broken
global npm install, not an omlx routing problem — it would block omp on every
runtime (lms/ollama/mlx/omlx alike), and `adapters/omp-ollama.sh` is presumably
equally broken. Note: `brew install omp` avoids this postinstall issue entirely.

Deferred rather than worked around: fixing a broken `bun` install is outside
the scope of "add omlx routes to existing agents" and risks masking the actual
question (does omp support a custom base URL at all) behind an unrelated fix.

## Revisit when

`bun`'s postinstall is run (`cd node_modules/bun && node install.js`, or a
clean reinstall) so `omp --help` succeeds — then check whether omp exposes a
`--provider`/custom-endpoint flag before writing `adapters/omp-omlx.sh`.

See also: [docs/HANDOFF-omlx-adapters.md](HANDOFF-omlx-adapters.md).

## Update (2026-08-11): bun install fixed, adapter verified working

The bun postinstall issue was hit and fixed independently (see
[AGENTS_CONFIG.md](../AGENTS_CONFIG.md), omp section). Generic fix:

```bash
node "$(npm root -g)/@oh-my-pi/pi-coding-agent/node_modules/bun/install.js"
```

`omp --help` now works (v17.2.12). Confirmed by decompiling the installed
`omp` binary (`dist/cli.js`): omp has **no built-in `omlx` provider** — it
only auto-registers `ollama`, `llama.cpp`, and `lm-studio` as local
providers. [adapters/omp-omlx.sh](../adapters/omp-omlx.sh) works around this
by pointing the `lm-studio` provider at the oMLX server via
`LM_STUDIO_BASE_URL`, then selecting `--model "lm-studio/$MODEL_ID"`. This
has now been smoke-tested live against a running oMLX server
(`Ornith-1.0-35B-4bit`) and produces real inference output — the adapter is
verified working, not just theorized.

One new lead, not yet investigated: `omp` now reports `~/.omp/agent/models.yml`
(not `models.json`) as its custom-provider config file when a model lookup
fails. That may be the correct place to register a first-class `omlx`
provider instead of routing through `lm-studio` — worth a follow-up to check
its schema and whether `/providers` then lists `omlx` natively.
