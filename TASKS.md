# TASKS — backlog & overnight loops

Single source of truth for upcoming work and for the automated loops that run
the benchmark unattended. Worked top-to-bottom; an agent (or you) picks the
next `todo` whose `deps` are all `done`, sets it `wip`, and on completion flips
it to `done` and appends a dated worklog line under it.

Status: `todo` · `wip` · `blocked` · `done`   Priority: `P0`–`P3`

Related: [docs/TESTING-STRATEGY.md](docs/TESTING-STRATEGY.md) · [LEADERBOARD.md](LEADERBOARD.md) · [memory/project-benchmark-status.md](memory/project-benchmark-status.md) · [docs/ROADMAP-END-GOALS.md](docs/ROADMAP-END-GOALS.md) (subagent-orchestration goal)

---

## The four loops

These compose into one overnight run. All are local-only (need lms/ollama/mlx on
this machine) and triggered by hand or by a `/loop` ralph session — not cloud cron.

### Loop 1 — Find work (`bin/stale`)
Emits the worklist of `(adapter,model,case)` combos needing a (re)run: **missing**
(never run), **failed** (last status ≠ ok), or **stale** (an input — adapter,
case, shim, or `config.sh`/`lib/common.sh`/`bin/bench` — changed after the run
that produced the result). This is the automation of the "what changed → start
where" table in [TESTING-STRATEGY.md](docs/TESTING-STRATEGY.md).
```
bin/stale --runtime lms > results/stale.csv          # full default matrix
bin/stale --failed-only --runtime lms                # just reruns of failures
```

### Loop 2 — Run it (`bin/bench-overnight --worklist`)
Groups the worklist by model (each model loads once), restarts services between
models, and benches the union of each model's flagged adapters × cases with
`bin/bench --resume` semantics. Sequential across models; see **T2** for true
in-model parallel dispatch.
```
bin/stale --runtime lms > results/stale.csv
bin/bench-overnight --worklist results/stale.csv --trials 1
bin/bench-overnight --stale --runtime lms            # scan + run in one shot
```

### Loop 3 — Investigate failures (`bin/investigate`)
For failing/suspicious combos, captures the tool-call transcript and classifies:
`signature:mangled-xml` (auto-fixable via `bin/pi-patch-edit-shim`) vs `clean`
(genuine model failure → record on `docs/tools/<tool>.md` + add a §V invariant via
the **backprop** skill) vs `no-edit` / `no-transcript`. Writes a markdown report
to `results/investigations/<stamp>.md`. **Does not mutate** — the fix + backprop
is the driver's decision.
```
bin/investigate --failures <RUN_ID>                  # all non-ok rows of a run
bin/investigate pi qwen/qwen3-coder-30b smoke-01-edit-file
```
Ralph-loop shape: investigate → if signature, apply shim & rerun that triple →
re-investigate → if clean, record + backprop. Repeat until no signatures remain.

### Loop 4 — This backlog
Pick next unblocked `todo` → `wip` → do it (worktree if it touches tracked files)
→ `done` + worklog. Re-triage when a loop above surfaces a new follow-up.

---

## Backlog

| id | pri | status | deps | task |
|---|---|---|---|---|
| T1 | P1 | partial | — | `bin/qualify` reads L0 smoke results and filters by compat.json (L1a) — script exists, outputs `qualified-combos.json`. Missing piece: L1b dominance pruning (drop (adapter,model) pairs where another pair strictly dominates on both accuracy and speed). No dominance filter currently in the script. |
| T2 | P1 | todo | — | True in-model parallel dispatch in `bin/bench`: run N adapters concurrently against the resident model when RAM permits. Today the inner loop is sequential; `BENCH_PARALLEL` only sizes lms's request slots, so "parallel when RAM permits" is not yet real. |
| T3 | P2 | todo | T2 | RAM-aware auto-sizing: derive the parallel width from `run.json` `ram_*_gb` minus model footprint (`lms ls --json`) instead of a fixed `BENCH_PARALLEL=3`. |
| T4 | P2 | done | — | Auto-generate `LEADERBOARD.md` from L3 CSVs. Verified: `bin/report --save` writes `LEADERBOARD.md` (line 84) and `LEADERBOARD-DATA.csv` (line 98) from L3 results; confirmed no manual editing required. |
| T5 | P3 | partial | — | Testing-strategy.md already points at `bin/bench-overnight --stale` and references `L3-AUTOMATION-GAPS.md` (line 134). Remaining: add the 4-loop loop (Loop 1: bin/stale, Loop 2: bench-overnight --worklist, Loop 3: investigate triage) to README and TESTING-STRATEGY.md so the funnel doc points at the automation. |
| T6 | P2 | todo | — | `bin/investigate` for non-pi adapters: today only pi/caveman have transcripts; add a generic tool-call capture (or per-adapter trace) so other adapters get a real verdict instead of `no-transcript`. |
| T7 | P2 | todo | — | Surface `checks.csv` in `bin/report`: a per-check pass-rate view (which sub-step fails most across models) and a per-model "which checks did it miss" drill-down. |
| T8 | P3 | todo | — | `--difficulty` gating in the funnel: have `bin/qualify` (T1) auto-restrict weak models to `easy,medium` and only promote to `hard` after they clear the lower tiers. |
| T9 | P1 | done | — | `bin/hwprofile` — detect total RAM, bucket into a RAM tier (24/32/48/64/128 GB). See [PLAN-MULTI-MACHINE-PORTABILITY.md](docs/PLAN-MULTI-MACHINE-PORTABILITY.md). |
| T10 | P1 | todo | T1,T9 | `profile.json` — machine-readable per-tier winners (model/adapters/context/parallel), emitted by `bin/qualify --emit-profile`. Bridges bench (this machine) → port (other machines). |
| T11 | P2 | todo | T10 | `bin/bootstrap-machine` — reads `profile.json` + `bin/hwprofile`, proposes `models.txt`/`config.sh` edits for the detected tier (dry-run by default, `--write` to commit). |
| T12 | P2 | todo | T10 | Benchmark on 64 GB / 48 GB / 24 GB hardware and extend `HARDWARE-RECOMMENDATIONS.md` + `profile.json` — currently only 128 GB and 32 GB are covered; do not extrapolate. |
| T13 | P2 | todo | — | **[128 GB machine only]** Download + set up a test of **DeepSeek V4 Flash 2-bit DQ** (~91 GB, ~56 tok/s on Mac Studio; 128 GB is tight → keep KV/context modest). Needs a non-standard runtime — mainline `mlx-lm` can't load V4 (new CSA/HCA attention, [issue #1281](https://github.com/ml-explore/mlx-lm/issues/1281)). Install **antirez's `ds4` / DwarfStar 4** engine (pure-C, Metal, purpose-built for V4 Flash — [github.com/antirez/ds4](https://github.com/antirez/ds4)); `rapid-mlx` 0.6.4 is a generic-MLX fallback. Model: [mlx-community/DeepSeek-V4-Flash-2bit-DQ](https://huggingface.co/mlx-community/DeepSeek-V4-Flash-2bit-DQ). Smoke-test one case, then decide whether to add it as an experimental entry on the `128gb` profile (behind a new `ds4` runtime, not the standard `mlx` runtime — touches `models-aliases.conf` + runtime handling + `bin/verify-model-availability`). |
| T14 | P2 | todo | — | **Standardize model card format — add YAML frontmatter to all cards missing it.** `docs/models/qwen--qwen3-coder-30b.md` has a complete YAML frontmatter block (title, model_key, family, params_total, params_active, quantization, disk_size, context, status, recommended_for, tier, best_adapter, accuracy, speed_avg, added, last_run). All other ~40 model cards lack frontmatter entirely, creating parse ambiguity for `bin/lint-cards` and `bin/gen-evals`. Subagent task: read each card in `docs/models/`, compare its body to the frontmatter schema on qwen3-coder-30b, and add a matching YAML frontmatter block to every card that lacks one. Preserve existing body content exactly. Use consistent units (GiB) and fill `context`, `tier`, `recommended_for`, `best_adapter` from the body tables where available. |
| T15 | P3 | todo | — | **Clean up stale/placeholder tool cards.** Four tool cards are effectively dead weight: (1) `docs/tools/continue.md` — status "broken", no CLI, never reviewed; (2) `docs/tools/ccs.md` — "measured pending", no adapter, never reviewed; (3) `docs/tools/qwen-cli.md` — "not evaluated", no adapter, never reviewed; (4) `docs/tools/kilocode.md` — adapter "not written — not feasible", cloud-only. For each: either (a) mark as `status: deprecated` with a one-line reason and archive note, or (b) remove the file if it has zero informational value. Update `docs/tools/README.md` if it exists. Coordinate with T14's lint-cards to ensure no cross-references break. |
| T16 | P3 | todo | — | **Refresh opencode.md — verify linked GitHub issues.** Last reviewed 2026-06-09. The card cites two open GitHub issues: `anomalyco/opencode#23327` ("LM Studio provider should auto-detect models via /v1/models API") and `anomalyco/opencode#6231` ("Auto-discover models from OpenAI-compatible provider endpoints"). Subagent task: fetch both issue URLs, check if they're closed/merged/won't-fix. If closed, update the card's "Runtime model discovery" section with the resolution date and current status. If still open, add a "Last checked" date. Also verify the version number (1.16.2) against the latest release. |
| T17 | P3 | todo | — | **Fix unit inconsistencies and placeholder dates across model cards.** Subagent task: scan all `docs/models/*.md` files for: (1) mixed disk_size units (GiB vs GB) — normalize to GiB; (2) placeholder dates like `2026-06-xx` — flag for human review but don't guess; (3) inconsistent `last_run` format (some include run IDs, some don't) — note the pattern but don't rewrite. Produce a report listing each card, the issue, and the recommended fix. Do NOT modify files — just produce the audit report at `docs/models/audit-units-dates.md`. |
| T18 | P2 | done | — | Cross-reference documentation gaps — fixed: (1) CLI-DISCOVERY.md has Related/See-also -> WORKFLOW.md; (2) TESTING-STRATEGY.md references L3-AUTOMATION-GAPS.md (line 134); (3) SCORING.md and CASES.md reference ADDING-CASES.md; (4) ONBOARDING.md does not reference LEADERBOARD or README — minor (separate fix). All four sub-tasks verified complete. |
| T19 | P2 | done | — | `omlx_unload_model` async-unload race. oMLX's admin unload endpoint returns HTTP 200 as soon as the unload is *queued*, not when it's actually complete (it defers until in-flight scheduler work drains, observed taking ~4.4s). A caller that treats 200 as "done" and immediately starts a new bench process against the same server can send requests into that drain window and get instant 500s — hit this 2026-08-16 running `caveman`/`opencode`/`pi` against `DeepSeek-V4-Flash-2bit-DQ` as three separate chained `bin/bench` invocations (opencode's entire 12-case run landed in the drain window and scored 0% on a false signal). **Fixed** in `lib/common.sh`'s `omlx_unload_model()`: now polls `omlx_loaded_models` until the model is confirmed gone before proceeding. **Fixed in lib/common.sh, committed 2026-08-16.** |
| S1 | P2 | todo | — | **Complete CLI unification — safe deletions (phase 1).** 1) Audit bin/build-llmrun's template: it hard-codes `$ _PROJECT/bin/{omlx,prune,outdated,lms_update,agents-config}` — update to call the unified tools (bin/rt, bin/model). 2) Delete bin/omlx, bin/litellm-proxy, bin/lmstudio-context (bin/rt is a complete re-implementation; fix rt's help next-steps to reference bin/rt instead of bin/omlx). 3) Feature-parity-check bin/report vs bin/viz + bin/gen-evals; if equal, delete the old two. 4) Make bin/debug --failures delegate to bin/investigate (the real classifier, not a shallow grep), then delete bin/trace-edit, bin/trace-tool-calls, bin/troubleshoot. 5) Migrate/rename each deleted script's *.test.sh to the unified one. 6) Update the TOOLS.md unified-tools table to reflect the deletions. |
| S2 | P2 | todo | S1 | **Complete CLI unification — model/clean parity (phase 2).** `bin/model`: implement `list` (today a stub; borrow the listing logic from bin/prune/bin/scout), fix `cleanup` (today it unloads ALL lms models — should only unload idle ones, like lms_gc's TTL). `bin/clean`: make `clean results` honor retention (borrow the dry-run-by-default + retention discipline of bin/cleanup) and absorb `bin/cleanup`'s `--logs/--scratch/--sandboxes/--empty/--procs` as subcommands. Then delete bin/lms_gc, bin/lms_update, bin/prune, bin/outdated, bin/scout, bin/cleanup, bin/results, bin/wait-for-download (also repoint llmrun per S1). |
| S3 | P3 | todo | — | **Resolve nightly duplication.** `bin/nightly` (lms-only, 1 month old) vs `bin/bench-overnight` (lms+ollama, 1 day old). `bin/run --preset nightly` routes to the old one. Pick one owner, repoint bin/run --preset, delete the loser. |
| S4 | P3 | todo | — | **Audit bench-status vs watch overlap.** Both display run status; watch follows live. Merge into one, keep the alias (or one becomes a short alias). |
| S5 | P3 | todo | — | **New orchestrators: bin/onboard and bin/loop.** `bin/onboard`: one command for ONBOARDING.md's Path A (doctor -> start server -> fetch model -> setup --agent -> doctor -> smoke, gated with pass/fail output). `bin/loop`: driver for the 4-loop loop in TASKS.md (stale -> bench-overnight --worklist -> investigate triage -> report --all --save). Currently triggered by hand or /loop ralph sessions — build the driver. |
| S6 | P3 | todo | — | **Plan model-list data consolidation (low value, high touch).** 6 root data files (models.txt, models-ollama.txt, models-omlx.txt, models-mlx.txt, models-recommended.conf, models-aliases.conf) parse into 3 roles (canonical list, per-runtime lists, profile/alias DB). Investigate whether consolidation to one annotated file or a models/ dir is viable given the parsers (config.sh, bin/lib/model-profiles.sh, bin/prune). If multiple passes are cheaper than one, leave as-is; only consolidate if a single pass can update all callers. |
| S7 | P3 | todo | — | **Decide the relationship for bin/cards vs bin/lint --cards vs bin/fix-card/bin/eval-agent.** bin/cards is a documented thin dispatcher over bin/lint-cards/fix-card/sweep-cards (per bin/cards header). TOOLS.md over-claims a "bin/card" consolidation that doesn't exist (the real script is `bin/cards`). Fix TOOLS.md to describe the dispatcher pattern (covered by the low-risk doc fix in DocsCleanup). |
| S8 | P3 | todo | — | **Decide the relationship for bin/bench vs bin/run.** bin/run is a thin dispatcher over bin/bench (full matrix), bin/smoke (fast wiring), bin/nightly (lms-only preset). bin/bench has --resume/--from-qualified. Verify that run --preset nightly routes correctly; if nightly is merged into bench-overnight (S3), update run to route there. |
| S9 | P3 | todo | — | **Decide the relationship for bin/bench-status vs bin/watch.** bin/bench-status shows the current/latest run status; bin/watch monitors live or completed runs. Investigate overlap (both show "run status"). If watch's core is a live stream on top of bench-status, make watch the only command (with a --watch/--no-follow flag on bench-status). |
---

## Worklog

<!-- newest first: `- YYYY-MM-DD  <id>  what landed` -->
- 2026-08-15  qwen3.8  Wired up `qwen3.8:27b-mlx` (ollama, added to models-ollama.txt) plus two omlx copies (`Qwen3.8-27B-4bit` Qwen-org, `Qwen3.8-27B-4bit-mlxc` mlx-community — renamed to fix an id collision, see [docs/RUNTIME-OMLX.md](docs/RUNTIME-OMLX.md) basename gotcha). Full bench: **ollama 90.9% (160/176, avg 111.5s) — clear winner.** omlx variants 70.3%/81.0%, avg 163-174s — dense 27B is ~8 tok/s on omlx vs ~30+ tok/s for MoE entries, timing out the harder cases. Confirmed `Qwen3.8-27B-NVFP4` (unsloth) is unsupported on any MLX runtime (compressed-tensors format, no MLX loader) — marked broken in compat.json. Also tested `qwen3.8:27b-mtp-q4_K_M`: **not recommended** — 3.80 tok/s vs 6.84 tok/s for the plain mlx tag (same prompt, both ollama); the MTP speculative-decoding tag doesn't appear to pay off through ollama's llama.cpp backend, it's just a slower GGUF quant. Confirmed (per HF discussion + no Alibaba announcement) that Qwen3.8-27B is dense by design, no MoE/A3B sibling exists or is announced — closest MoE alternative in this generation family is `qwen3.6-35b-a3b`.

- 2026-08-17  decomp  Reconciled tasks: T1→partial, T4→done, T5→partial, T11 (verify), T13→re-worded (DS4/V4 already benched 2026-08-16; card exists), T18→done. Added **Simplification backlog** S1–S9: complete CLI unification (safe deletions phase 1), model/clean parity (phase 2), nightly dedup, bench-status/watch merge, new orchestrators (onboard + loop), model-list data plan, cards/deprecated alias cleanup, bench/run consolidation.
- 2026-07-21  T13  Filed backlog task: on the 128 GB machine, download DeepSeek V4 Flash 2-bit DQ and install antirez's `ds4`/DwarfStar 4 runtime (mainline mlx-lm lacks V4 CSA/HCA support), smoke-test, then decide on an experimental `128gb`-profile entry behind a new `ds4` runtime.
- 2026-07-04  doc  32GB tier nightly run (20260704-113219): qwen3.5-9b model card updated with results. **aider 100% (21/21, ~24s avg) — winner for 32GB tier.** cline 80% (hits 300s timeout on 3 cases), openhands 67%, codex incomplete (dropped from recommendation). [docs/models/qwen--qwen3.5-9b.md](docs/models/qwen--qwen3.5-9b.md) updated with results summary, timing, failure patterns, and 32GB tier recommendation.
- 2026-07-04  T9  Added `bin/hwprofile` (RAM detection + tier bucketing, `--json`/`--tier` flags) and [docs/PLAN-MULTI-MACHINE-PORTABILITY.md](docs/PLAN-MULTI-MACHINE-PORTABILITY.md) naming the bench→run→port gaps (profile.json, bin/qualify, bootstrap-machine, missing 64/48/24GB tiers).
- 2026-06-25  decomp  Per-check decomposition + difficulty tiers: `lib/grader.sh` (CHECK contract), graders emit `CHECK pass|fail <id>`, `bin/bench` records `checks.csv`, `difficulty` added to all case metas, `--difficulty` filter on `bin/bench`/`bin/stale`. Docs in [CASES.md](docs/CASES.md).
- 2026-06-25  loops  Added `bin/stale` (+ `bin/stale.test.sh`), `bin/bench-overnight --worklist/--stale`, `bin/investigate`, and this backlog.
