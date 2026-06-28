# Plan: `bin/prune` — safe pruning of outdated benchmark runs (opencode)

**Status**: proposed
**Date**: 2026-06-13
**Session start**: 2026-06-13T15:00:00Z (Europe/Copenhagen, UTC+2)
**Plan created**: 2026-06-13T15:05:00Z
**Duration**: ~5 minutes
**Input question**: "we would like a way to prune outdated results. Outdated results could be duplicates, or misconfigured runs where we later had a better run. How would you do that? I want to be sure we dont lose unique results"
**Tool**: opencode — model `qwen/qwen3.6-35b-a3b` (model ID: qwen/qwen3.6-35b-a3b)

---

## Problem

You have ~120 run directories in `results/`. Many are duplicates (same adapter + model + case + runtime). `bin/report --all` already deduplicates by taking the latest per tuple, so older duplicates contribute zero data but consume disk.

The challenge: **don't delete runs that are actually unique** (different case coverage, different config).

---

## Safety guarantees

1. **Never deletes a run that is the sole contributor to any (adapter, model, case, runtime) cell** — `bin/report --all` would lose data.
2. **Never deletes the latest run for any (adapter, model, case, runtime) tuple** — that's the one `bin/report --all` uses.
3. **Dry-run first** — every prune mode shows what would be deleted before doing it.
4. **Move to `_archive/` not rm** — archived runs are recoverable.

---

## Design

### Entry

```
bin/prune [--auto] [--interactive] [--archive] [--dry-run] [--runtime <lms|ollama|mlx>] [--date-before YYYY-MM-DD] [--date-after YYYY-MM-DD] [--adapter <name>] [--model <id>]
```

### Deduplication key

Same as `bin/report --all`: `(adapter, model, case, runtime)`.

For each key, we group all runs that contain it. The latest (by run timestamp) wins. Everything else in the group is a candidate for pruning.

### Pruning modes

#### `--auto` — safe duplicate removal

For each (adapter, model, case, runtime) key:
- If there's only one run → **keep** (unique, no duplicate)
- If there are multiple runs → **keep the latest**, mark others as prunable

Shows a summary:
```
Found 120 runs covering 47 unique (adapter, model, case, runtime) keys.

  73 runs are the latest for their key — KEEP (unique or latest)
  47 runs are older duplicates — PRUNE

  By runtime:
    lms:  68 runs (12 prunable)
    ollama: 38 runs (21 prunable)
    mlx:   14 runs (14 prunable)

  by adapter:
    copilot: 25 runs (8 prunable)
    hermes:  22 runs (10 prunable)
    ...
```

#### `--interactive` — user-controlled picker

Uses fzf to let you pick which runs to archive. Runs are grouped by key so you can see which ones are duplicates:

```
  [✓] 20260610-081234  copilot  qwen3.5-9b    js-01-slugify-bug  lms  (dup of 20260612-140000)
  [✓] 20260612-140000  copilot  qwen3.5-9b    js-01-slugify-bug  lms  ← latest, locked
  [✓] 20260609-220000  hermes   gemma4-26b     bash-01-topwords   lms  (unique)
  [✓] 20260611-093000  aider    qwen3-coder    js-03-multifile    ollawa  (dup of 20260613-060000)
  ...
```

- Latest runs per key are **locked** (can't be deselected)
- Unique runs are **soft-locked** (can be deselected but show a warning)
- Duplicates are freely selectable

#### `--interactive --auto` — hybrid

First marks all auto-prunable duplicates, then opens the picker so you can review/change before confirming.

### Filtering

Before grouping, apply filters:

| Flag | Effect |
|---|---|
| `--runtime <lms|ollama|mlx>` | Only consider runs with this runtime |
| `--date-before YYYY-MM-DD` | Only runs before this date |
| `--date-after YYYY-MM-DD` | Only runs after this date |
| `--adapter <name>` | Only runs with this adapter |
| `--model <id>` | Only runs with this model |

Filters combine with AND logic.

### Archive format

```
results/_archive/
  20260610-081234/          # original timestamped dir preserved
  20260609-220000/
  ...
```

Archived dirs are moved (not copied) from their original location. If the original run was the sole contributor to any key, it's skipped with a note.

### What gets pruned

A run is prunable when ALL of:
1. It's not the latest for its (adapter, model, case, runtime) key
2. No other run in the same key has significantly better scores (option: `--keep-best` mode to also keep the highest-scoring run per key, not just the latest)
3. It passes the user's filters (if any)

### `--keep-best` mode (optional enhancement)

Sometimes an older run has better scores (e.g., the model was misconfigured in the newer run). This mode:
- For each key, keeps both the latest run AND the highest-scoring run
- Marks everything else as prunable

```
  [✓] 20260610-081234  copilot  qwen3.5-9b    js-01-slugify-bug  lms  score=0.75  (dup, latest=20260612)
  [✓] 20260612-140000  copilot  qwen3.5-9b    js-01-slugify-bug  lms  score=0.50  ← latest
  [✓] 20260605-100000  copilot  qwen3.5-9b    js-01-slugify-bug  lms  score=0.90  ← best score, KEEP
```

### Execution flow

```
bin/prune [--flags]
  │
  ├── 1. Scan all results/<timestamp>/ directories
  ├── 2. Read run.json + results.csv from each
  ├── 3. Apply filters (if any)
  ├── 4. Group by (adapter, model, case, runtime)
  ├── 5. Identify latest per group
  ├── 6. Identify best score per group (if --keep-best)
  ├── 7. Mark prunable runs
  ├── 8. Show summary / open picker
  ├── 9. Confirm (or --dry-run)
  └── 10. Move pruned dirs → results/_archive/
```

---

## Files to create / modify

| File | Action |
|---|---|
| `bin/prune` | Create (new script, ~250-350 lines) |
| `lib/common.sh` | Add `archive_run`, `restore_run` helpers |
| `results/_archive/` | Create (empty directory) |

### `bin/prune` structure

```
bin/prune
├── parse_opts (flags)
├── scan_runs (read all results/<timestamp>/ dirs)
├── apply_filters (runtime, date, tool, model)
├── group_by_key (aggregate by adapter+model+case+runtime)
├── identify_latest (per group, find the winner)
├── identify_best (optional --keep-best)
├── compute_prunable (latest + unique are safe; rest are candidates)
├── show_summary (--auto) OR open_fzf_picker (--interactive)
├── confirm (--dry-run skips here)
└── move_to_archive (mv → results/_archive/)
```

### Key helpers to add to `lib/common.sh`

```bash
# Move a run directory to archive, return archive path
archive_run <run_id> → results/_archive/<run_id>/

# List archived runs
list_archived → prints run_ids from results/_archive/

# Restore an archived run
restore_run <run_id> → mv results/_archive/<run_id>/ results/<run_id>/

# Check if a run is the sole contributor to any key
is_sole_contributor <run_id> → 0/1 (used for safety guard)
```

---

## Open questions

1. **Should `--keep-best` be default or opt-in?**
   - Default: safer, keeps more data, less disk savings
   - Opt-in: faster pruning, but risks losing a genuinely better run
   - **Recommendation**: opt-in, but `--auto` warns "X runs had better scores than their latest — use --keep-best to preserve them"

2. **Should we archive by runtime subdirectory?**
   - `results/_archive/lms/20260610-081234/` — easier to restore by runtime
   - Flat `results/_archive/20260610-081234/` — simpler, mirrors original structure
   - **Recommendation**: flat, mirrors original. Runtime is already in run.json.

3. **Should pruning regenerate the leaderboard?**
   - After pruning, `bin/report --all --save` would become stale if the archived run was the latest for some key
   - **Recommendation**: warn the user to re-run `bin/report --all --save` after pruning. Don't auto-regenerate.

4. **Should we track what was pruned?**
   - A `results/_archive/.prune-log.json` recording what was moved and when
   - Useful for auditing: "what did we remove and why?"
   - **Recommendation**: yes, simple JSON array of `{run_id, date, reason: "duplicate|manual", archived_at}`

5. **Disk space reporting?**
   - Show `du -sh` per group so the user sees the impact
   - **Recommendation**: yes, include in the summary

---

## Summary of safety checks

| Check | Action |
|---|---|
| Run is the sole contributor to any key | **Skip** — pruning would lose data |
| Run is the latest for its key | **Skip** — pruning would change leaderboard |
| Run is the best-scoring for its key | Warn user (unless `--keep-best`) |
| `--dry-run` flag | Show what would happen, make no changes |
| No `--yes` flag | Always prompt before moving to archive |
| Archive dir already has the run ID | Skip (already archived, don't double-move) |
