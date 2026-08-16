# Handoff: add omlx adapters for all agents

**Date:** 2026-08-08
**Goal:** every agent in `adapters/` should have an `omlx` route, smoke-tested
against oMLX and committed.

## Where things stand right now

Of the ~18 agents this repo drives, only **3 currently support `--runtime
omlx`**:

| adapter | omlx file |
|---|---|
| pi | `adapters/pi-omlx.sh` |
| aider | `adapters/aider.sh` (unified — branches on `$RUNTIME`) |
| opencode | `adapters/opencode-omlx.sh` |

Verified working 2026-08-08: `bin/smoke --runtime omlx --model
Ornith-1.0-35B-4bit --agent pi,aider,opencode` → **9/9 pass** (all three
adapters, all three smoke cases). See `results/20260808-111009/`.

Everything else has **no adapter file for omlx at all** — `bin/bench`/`bin/smoke`
fall back `adapters/<name>-omlx.sh` → `adapters/<name>.sh` (unified), and
neither exists for these, so they can't even attempt to run:

```
cline, codex, caveman, hermes, interpreter, openhands, goose, copilot,
claude, cn, forge, gptme, mini-swe-agent, nanocoder, omp
```

## What already exists per agent (build from these, don't start from scratch)

Agents with an `-mlx.sh` variant already (closest template — both mlx and omlx
are local OpenAI-compatible MLX servers, differing mainly in base URL/env var
and whether the id is a bare directory name):

- `cline-mlx.sh`, `codex-mlx.sh`, `caveman-mlx.sh`, `hermes-mlx.sh`, `copilot-mlx.sh`

Agents with only `-lms.sh`/`-ollama.sh` (no mlx precedent — adapt from `-lms.sh`,
swap `LMS_BASE_URL`/`LMS_API_KEY` for `OMLX_BASE_URL`/`OMLX_API_KEY`, and check
whether the agent needs a model-metadata file the way aider/pi do for bare
directory-name ids):

- `interpreter-lms.sh`, `openhands-lms.sh`, `goose-lms.sh`, `claude-lms.sh`,
  `cn-lms.sh`, `forge-lms.sh`, `gptme-lms.sh`, `mini-swe-agent-lms.sh`,
  `nanocoder-lms.sh`
- `omp` only has `-ollama.sh` — check if omp even supports an OpenAI-compatible
  custom endpoint before attempting.

## Known blockers — don't force these, verify first

- **interpreter**: per `docs/MODEL-DISCOVERY.md`, it uses a **hardcoded**
  built-in `lmstudio` provider at `localhost:1234` and ignores `LMS_BASE_URL`
  entirely. There may be no way to point it at oMLX's port at all — check
  upstream for a `--api-base`/custom-provider flag before writing
  `interpreter-omlx.sh`; if genuinely impossible, document it as a decision
  (pattern: `docs/DECISION-amp-cloud-only.md`) rather than leaving a stub.
- **copilot**: documented across `lms`/`mlx`/`ollama` as fundamentally
  incompatible with local coder models' patch format (`docs/AGENT-SELECTION.md`
  — "Patch format incompatible with most models"). An omlx variant would likely
  hit the same wall; low priority, verify smoke result rather than assuming.
- **caveman**: was broken on LMS from 2026-06-28–2026-07-07 for an unrelated
  reason (missing `~/.cave/agent/models.json`, not a runtime issue) — already
  fixed, see `docs/tools/caveman.md`. Its omlx variant should follow the same
  provider-config pattern (own `~/.cave/agent/models.json`, needs an `omlx`
  provider entry added).

## Model-catalog agents (need config entries, not just adapter scripts)

Agents that read a **static model list** instead of querying `/v1/models` need
an `omlx` provider block added to their own config file before the adapter
script will find the model at all (see `docs/MODEL-DISCOVERY.md`):

- `pi` → `~/.pi/agent/models.json` (already has omlx + Ornith-1.0-35B-4bit)
- `caveman` → `~/.cave/agent/models.json` (has no omlx provider yet — add one,
  mirroring `~/.pi/agent/models.json`'s omlx block)
- `opencode` → `~/.config/opencode/opencode.jsonc` (already has omlx)
- `hermes` → `~/.hermes/config.yaml` (no omlx provider yet, and per
  `docs/MODEL-DISCOVERY.md` this file is already **drifting/stale** even for
  lmstudio — worth a broader sync fix while touching it)
- `cn` → its own generated `config.yaml` (adapter regenerates it per run
  already, per `docs/MODEL-DISCOVERY.md` — check if that generator branches on
  runtime)

`bin/agents-config` (see `bin/agents-config:33` comment: "The omlx provider is
synced only when the agent's config already declares it") already has the sync
logic for pi/opencode/caveman — it just needs each config file to declare the
`omlx` block once, then `bin/agents-config --write` keeps it current. Extend
`bin/agents-config` itself if adding hermes/cn to that same sync path.

## Environment gotcha (this machine only)

`config.sh` defaults `OMLX_BASE_URL` to port 4000 (oMLX's documented default),
but **this machine's oMLX actually runs on port 8000** (`~/.omlx/settings.json`
diverges from default). Every command in this task needs:

```bash
export OMLX_BASE_URL="http://127.0.0.1:8000/v1"
```

Do not "fix" `config.sh`'s default to 8000 — that would break machines where
oMLX actually runs on its documented default port. This is local-machine state,
not a repo bug.

## Plan for the new thread

1. Pick up agents in small batches (e.g. the 5 with an `-mlx.sh` precedent
   first — least novel work).
2. For each: write `adapters/<name>-omlx.sh` adapted from the closest existing
   variant (mlx if present, else lms). Add any needed `omlx` provider config
   entry (models.json / config.yaml / etc.) per the table above.
3. Smoke-test individually before batching:
   ```bash
   export OMLX_BASE_URL="http://127.0.0.1:8000/v1"
   bin/smoke --runtime omlx --model Ornith-1.0-35B-4bit --agent <name> -v
   ```
4. If a case fails, re-run in isolation once before concluding it's broken —
   2026-08-08's pi run showed a resource-contention flake (stall) when 3 heavy
   adapters ran back-to-back on this 35B model; isolate before writing to
   `compat.json`.
5. Once verified passing, `git add` the new adapter + any config-template
   changes and commit **per adapter or small batch** (not one giant commit) —
   easier to bisect if a later regression appears.
6. Update `docs/AGENT-SELECTION.md` and the relevant `docs/tools/<name>.md` to
   note omlx support once verified.
7. For interpreter/copilot: if genuinely blocked, write a short decision note
   instead of a broken/half-working adapter (see `docs/DECISION-amp-cloud-only.md`
   as the template for "investigated, here's why not").

## Reference commits from this session

- `2aa2b33` — docs: fix stale AGENT-SELECTION.md entries for pi and caveman
  (unrelated cleanup found while smoke-testing the existing 3 omlx adapters)
