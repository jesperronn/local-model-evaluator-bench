# Decision: interpreter — no omlx adapter

**Date:** 2026-08-08
**Status:** Skip — not achievable with the installed version

## Context

Every other agent in this harness reaches non-LMS runtimes (mlx, ollama, omlx)
through a custom/override provider pointed at `$X_BASE_URL`. `interpreter`
(Open Interpreter) was checked for the same escape hatch before writing
`adapters/interpreter-omlx.sh`.

## Decision

Skip. Per [docs/MODEL-DISCOVERY.md](MODEL-DISCOVERY.md) (Known breakage
section), `interpreter` uses a **hardcoded** built-in `lmstudio` provider at
`localhost:1234` and ignores `LMS_BASE_URL` (and by extension any
`OMLX_BASE_URL`) entirely — `--runtime` other than `lms` silently talks to LM
Studio instead of the intended backend. This is the same reason there is no
`interpreter-mlx.sh` or `interpreter-ollama.sh` custom-endpoint variant (the
existing `interpreter-ollama.sh` works only because Open Interpreter has a
*second* hardcoded built-in provider for Ollama specifically — there is no
third hardcoded slot for oMLX).

No `--api-base`/custom-provider flag was found that overrides this for an
arbitrary OpenAI-compatible endpoint like oMLX.

## Revisit when

Open Interpreter ships a custom-provider / arbitrary-base-url mode. Until
then, skip without re-investigating if omlx support comes up again.

See also: [docs/HANDOFF-omlx-adapters.md](HANDOFF-omlx-adapters.md),
[docs/MODEL-DISCOVERY.md](MODEL-DISCOVERY.md),
[docs/DECISION-amp-cloud-only.md](DECISION-amp-cloud-only.md) (template).
