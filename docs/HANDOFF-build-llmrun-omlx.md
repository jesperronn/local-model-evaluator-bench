# Handoff: add `omlx` as a fourth runtime in `bin/build-llmrun`

**Date:** 2026-08-08
**Goal:** `llmrun --runtime omlx` works end-to-end for every adapter that has
an `-omlx.sh` variant, and `omlx` shows up correctly in the runtime picker,
`llmrun runtime status/start/stop/logs`, and `--dry-run` output.

## Why this exists

While registering `qwen-omlx.sh` as a harness (see
`docs/HANDOFF-phone-home-audit.md` for that session's other finding), it came
up that `bin/build-llmrun` — the generator for the standalone `llmrun` CLI —
has **zero mentions of `omlx` anywhere in the file**. `grep -n omlx
bin/build-llmrun` returns nothing. This isn't specific to qwen: it affects
every omlx adapter, including `pi-omlx.sh` and `opencode-omlx.sh`, which
existed before this session and already work fine through `bin/bench`/`bin/smoke`
(those resolve adapters directly from the filesystem with no runtime
allowlist). `build-llmrun`'s generated `llmrun`, by contrast, hardcodes
exactly three runtimes throughout.

Net effect today: `bin/bench --agent qwen --runtime omlx` works; the
installed `llmrun --agent qwen --runtime omlx` does not, because `omlx` isn't
a recognized `--runtime` value and won't even appear in the fzf picker.

## Where `lms`/`ollama`/`mlx` are hardcoded (fix all of these)

All line numbers below are from `bin/build-llmrun` as of commit `8b7cd5a`
(2026-08-08) — re-check with `grep -n` before editing, this file moves.

1. **Health-check functions** (~line 71-76): `lms_up()`, `ollama_up()`,
   `mlx_up()`. Need an `omlx_up()` — probably
   `curl -fsS --max-time 5 "$_OMLX_URL/models"`, mirroring `lms_up()`. Needs
   a baked-in `_OMLX_URL` constant analogous to `_LMS_URL`/`_LMS_KEY` (see
   the `sed` template substitution block at the top of the file, ~line 26-33,
   and the `_LMS_URL=`/`_LMS_KEY=` baked-in vars at ~line 55-56) — source
   these from `$OMLX_BASE_URL`/`$OMLX_API_KEY` in `config.sh`, same pattern
   as the existing LMS ones.

2. **`llmrun runtime status`** (`rt_status_one()`, ~line 90-127): has a
   `case` arm per runtime (`lms`, `ollama`, `mlx`) that prints up/down +
   loaded model. Needs an `omlx)` arm. oMLX's `/v1/models` returns the full
   inventory (not just the currently-loaded model, unlike mlx_lm.server) —
   see `docs/RUNTIME-OMLX.md` for the semantic difference; decide whether
   "loaded" for omlx should list all served models or just note server-up
   (oMLX LRU-swaps, so nothing is meaningfully "loaded" until first request).

3. **`llmrun runtime start/stop/logs`** (`cmd_runtime_start/stop/logs`,
   ~line 129-260ish): same three-way `case` pattern. `bin/omlx start/stop`
   already exists as the project's own lifecycle script — the `omlx)` arms
   here should probably just shell out to it (`"$_PROJECT/bin/omlx" start`),
   the way `mlx)` shells out to `mlx_lm.server` directly. Confirm `bin/omlx`
   is usable standalone from outside the repo (same constraint `llmrun`
   already has for LMS/Ollama/MLX — it's meant to run from dotfiles without
   depending on `$_PROJECT` for anything but adapter paths).

4. **Model listing for the picker** (`--list-models`-ish block ~line 683-703
   and the `MODEL` selection block ~line 738-763): `lms`/`ollama`/`mlx` each
   have a live-server path (`lms ls`, `ollama list`, `/v1/models`) and a
   static-file fallback (`models-ollama.txt`, `models-mlx.txt`). Needs an
   `omlx)` case hitting `$_OMLX_URL/models` live, falling back to
   `models-omlx.txt` (already exists in the repo — `ls models-omlx.txt` —
   confirm its format matches what the fallback path expects, i.e. one model
   ID per line, comments stripped by `read_list()`).

5. **Tool→runtime picker filter** (~line 715-724):
   ```bash
   runtimes="$(all_adapters | grep -E "^${TOOL}-" | grep -oE '(lms|ollama|mlx)$' | sort -u)"
   ```
   The `grep -oE` pattern needs `omlx` added:
   `(lms|ollama|mlx|omlx)$`. Without this, `qwen-omlx.sh` is invisible to
   the picker even after everything else is fixed — this is probably the
   single most important line to change, everything else is reachable only
   after this.

6. **`--dry-run` output** (~line 783-789): prints `LMS_BASE_URL`/`LMS_API_KEY`
   resolved per runtime. Needs an `omlx)` arm (`dr_url="$_OMLX_URL"
   dr_key="$_OMLX_KEY"`). Check `bin/build-llmrun.test.sh` (added in commit
   `883af36`) for existing dry-run assertions to extend — this test file is
   exactly where an `omlx` case should get covered.

7. **Runtime up-check before exec** (~line 798-801): `case "$RUNTIME" in
   lms) lms_up || die ...` — needs `omlx) omlx_up || die "oMLX not reachable
   at $_OMLX_URL — start with: bin/omlx start"`.

8. **Final env-export block before exec** (~line 817-824) — the one with the
   comment explaining *why* this matters ("without this a `--runtime ollama`
   run would silently talk to LM Studio"). This is the load-bearing one:
   ```bash
   case "$RUNTIME" in
     lms)    export LMS_BASE_URL="$_LMS_URL"                 LMS_API_KEY="$_LMS_KEY";;
     ollama) export LMS_BASE_URL="http://localhost:11434/v1" LMS_API_KEY="ollama";;
     mlx)    export LMS_BASE_URL="http://localhost:8080/v1"  LMS_API_KEY="not-needed";;
   esac
   ```
   **Careful here:** omlx adapters (`pi-omlx.sh`, `opencode-omlx.sh`,
   `qwen-omlx.sh`) all `source config.sh` and read `$OMLX_BASE_URL`/
   `$OMLX_API_KEY`, **not** `$LMS_BASE_URL`/`$LMS_API_KEY` — unlike the
   unified lms/ollama/mlx adapters, which all reuse the `LMS_*` var names
   for whichever backend was selected (that's *why* this block exists: to
   repoint the shared `LMS_*` names). So the new arm is NOT
   `omlx) export LMS_BASE_URL=... ;;` — it must export
   `OMLX_BASE_URL`/`OMLX_API_KEY` instead. Get this wrong and adapters will
   silently fall back to whatever `OMLX_BASE_URL` default `config.sh` has
   (currently `http://127.0.0.1:8000/v1`), which happens to work on this
   machine but would be wrong the moment `--runtime omlx` is meant to hit a
   non-default port.

## Verification checklist before calling this done

```bash
cd <repo> && bin/build-llmrun            # regenerate
llmrun --agent qwen --runtime omlx --model Ornith-1.0-35B-4bit --dry-run
llmrun --agent qwen --runtime omlx --model Ornith-1.0-35B-4bit "say hi"
llmrun runtime status omlx
llmrun runtime status              # confirm omlx line appears alongside lms/ollama/mlx
bash bin/build-llmrun.test.sh      # extend with omlx dry-run case, then run
```

Also re-run the network-capture check from `docs/HANDOFF-phone-home-audit.md`
against the `llmrun`-launched qwen invocation specifically — the suppression
env vars live inside `adapters/qwen-omlx.sh`, but worth confirming
`build-llmrun`'s env-export block (item 8 above) doesn't clobber or
short-circuit anything the adapter sets.

## Non-goals for this handoff

- Not touching `bin/bench`/`bin/smoke`'s adapter resolution — those already
  handle omlx correctly and aren't in scope.
- Not auditing whether every `-omlx.sh` adapter is itself phone-home-clean —
  that's `docs/HANDOFF-phone-home-audit.md`'s job, this handoff is purely
  about `build-llmrun` recognizing omlx as a runtime at all.
