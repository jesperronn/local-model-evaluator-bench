# Implementation: Adapter Compatibility Management

## Summary

Implemented an automated system for tracking and filtering broken adapter+model+runtime combinations to avoid wasting time on incompatible configurations.

## Changes Made

### 1. Core Library Functions (`lib/common.sh`)

Added two new functions:

- **`filter_broken_adapters(adapters_csv, model, runtime)`**
  - Reads `compat.json` and filters out adapters with `status="open"`
  - Returns comma-separated list of working adapters
  - Safely handles missing `compat.json` (returns all adapters)
  - **Usage**: Called by bin/bench before running trials

- **`warn_filtered_adapters(original_csv, filtered_csv, model, runtime)`**
  - Pretty-prints which adapters were excluded and why
  - Shows the symptom (first error) for each incompatible adapter
  - **Usage**: Called by bin/bench to inform user of skipped adapters

### 2. Enhanced bin/bench

**New behavior**: Automatically filters out broken adapters before running trials.

- Calls `filter_broken_adapters()` after resolving model list
- Shows warning with symptoms of filtered adapters
- Dies with clear error if all adapters are filtered out
- Prevents wasted compute time on known-broken configurations

**Example output**:
```
[WARN] skipping 3 adapter(s) with known incompatibilities for qwen/qwen3.6-35b-a3b on lms:
      copilot: copilot: command not found
      hermes: failed to connect to control plane
      interpreter: connection timeout
```

### 3. Enhanced bin/smoke

**New flag**: `--skip-compat-update`
- By default, smoke tests update `compat.json` with results
- `--skip-compat-update` runs tests but doesn't record results
- Useful when iterating on adapter changes before committing them

**Example**:
```bash
bin/smoke --adapter copilot --skip-compat-update  # Test without recording
bin/smoke --adapter copilot                       # Test and update compat.json
```

### 4. Compatibility Tracking (compat.json)

The existing `compat.json` system now fully drives the filtering:

```json
{
  "copilot:google/gemma-4-e2b:lms": {
    "adapter": "copilot",
    "model": "google/gemma-4-e2b",
    "runtime": "lms",
    "status": "open",  ← filtered out by bin/bench
    "symptom": "copilot: command not found",
    "first_seen": "2024-01-15",
    "last_seen": "2024-01-20"
  },
  "aider:google/gemma-4-e2b:lms": {
    "status": "resolved"  ← included by bin/bench
  }
}
```

Statuses:
- **"open"** — broken, not run
- **"resolved"** — working, run normally
- **"none"** — unknown (new combo), included and tested
- **"regressed"** — was fixed, now broken again

### 5. Comprehensive Workflow Documentation

Created [`docs/WORKFLOW.md`](../docs/WORKFLOW.md) covering:
- Adding a new adapter (step by step)
- Adding a new model
- Running smoke tests (all variants)
- Understanding smoke test results
- Managing broken/incompatible adapters
- Re-evaluating abandoned/fixed adapters
- Full workflow example
- Maintenance commands

### 6. Test Suite

Created [`lib/common.test.sh`](../lib/common.test.sh) with 11 tests:

```bash
bash lib/common.test.sh
# [PASS] filter removes broken, keeps good
# [PASS] filter preserves unknown adapters
# [PASS] filter removes multiple broken
# ... 8 more tests
# all 11 passed
```

Covers:
- Filtering broken adapters
- Preserving unknown adapters
- Handling empty inputs
- Missing compat.json
- Warning output

### 7. Updated README

Added prominent link to [`WORKFLOW.md`](../docs/WORKFLOW.md) in the documentation section, positioned as the entry point for getting started with the workflow.

## Workflow in Action

### Before (manual tracking)

```bash
# Run benchmark
bin/bench --model qwen/qwen3.6-35b-a3b
# ⏱ 2 hours later, discovers copilot adapter doesn't work
# 😞 Wasted time on broken adapter
```

### After (automatic filtering)

```bash
# Run smoke test (auto-updates compat.json)
bin/smoke --model qwen/qwen3.6-35b-a3b

# Run benchmark (auto-skips broken adapters)
bin/bench --model qwen/qwen3.6-35b-a3b
# [WARN] skipping copilot: command not found
# ✅ No wasted time
```

## Key Design Decisions

1. **Filtering in bin/bench only** — Smoke test is fast enough to run all adapters; bench is where we save time
2. **Opt-in compat updates** — Default to update, but `--skip-compat-update` allows iteration without committing
3. **First model only** — bin/bench filters based on the first model in the list (adapters incompatible with one model likely fail with others)
4. **Silent on missing compat.json** — New users won't have compat.json yet; graceful fallback to running all adapters
5. **Human-readable symptoms** — Stored in compat.json for context; shown in warning messages

## Testing

Run the test suite to verify the filtering logic:

```bash
bash lib/common.test.sh
```

All 11 tests should pass. Tests cover:
- Filtering broken/good/unknown adapters
- Empty inputs
- Missing compat.json
- Warning output formatting

## Next Steps

1. Run your first smoke test: `bin/smoke --model <your-model>`
2. Check compat.json: `jq . compat.json | head -50`
3. Run bench (will auto-skip broken adapters): `bin/bench --model <your-model> --timeout 600`
4. See full workflow in [`docs/WORKFLOW.md`](../docs/WORKFLOW.md)

## Backwards Compatibility

- ✅ No breaking changes to existing bin/bench or bin/smoke behavior
- ✅ compat.json is optional (existed before, enhanced now)
- ✅ Filtering is transparent (shows warnings, no silent behavior)
- ✅ `--skip-compat-update` is optional, defaults to updating
