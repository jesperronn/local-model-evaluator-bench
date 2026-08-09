# kilocode

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Kilo Code |
| **CLI command** | `kilo` |
| **npm package** | `@kilocode/cli` |
| **Version** | 7.3.46 |
| **Adapter script** | not written — not feasible (see Status) |
| **How it connects** | N/A |
| **Runtime model discovery** | **yes, but against the wrong backend** — kilo validates every model ID against kilo.ai's cloud catalog, not the local `OPENAI_BASE_URL` endpoint. That's precisely why local models are rejected (see Status/Investigation notes below): `kilo run --model openai/<anything>` errors "Model not found" even with the base URL pointed locally, because the model list it checks against is fetched from kilo.ai. **Matches an upstream feature request that was closed as not planned:** [Kilo-Org/kilocode#6326 — "[FEATURE]: Add Ollama/Local Model Provider Support"](https://github.com/Kilo-Org/kilocode/issues/6326) (closed as not planned, despite the requester reporting a working implementation) — confirms local/Ollama provider support for the CLI is a known, deliberately-declined request, not an oversight. Re-check periodically in case that decision changes. |
| **Last reviewed** | 2026-06-18 |

## Status

**not feasible** — kilo validates all model IDs against kilo.ai's cloud backend. Even with `OPENAI_BASE_URL` set, `kilo run --model openai/<anything>` errors with "Model not found" because the model list is fetched from kilo.ai, not the local endpoint. BYOK (bring-your-own-key) openai-compatible providers require interactive `kilo auth login -p openai-compatible` which writes credentials to a SQLite DB and authenticates via kilo.ai — not scriptable non-interactively.

Kilo is cloud-first by design. Local model support is not exposed without going through their auth flow.

## Investigation notes

Investigated 2026-06-18:

- `kilo run -m openai/qwen3.6-35b-a3b --auto` with `OPENAI_BASE_URL=http://localhost:1234/v1` → "Model not found: openai/qwen3.6-35b-a3b" (kilo.ai validates the model list server-side)
- `kilo models` shows only kilo.ai-registered models; no local/custom endpoint option
- Config file (`~/.config/kilo/kilo.jsonc`) has `model` field but only accepts kilo.ai model IDs
- BYOK openai-compatible provider exists in the bundle (`openai-compatible` in auth provider list) but requires interactive login that stores credentials in `~/.local/share/kilo/kilo.db` via kilo.ai's OAuth flow
- No `--data-dir` flag (unlike cline); provider config is global and DB-backed

**If kilo adds local/offline provider support in a future version**, the adapter would likely be similar to cline: configure the openai-compatible provider non-interactively and pass `--auto` for unattended runs.
