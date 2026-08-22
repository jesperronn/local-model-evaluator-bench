---
name: model-add
description: Add a new model to the benchmark interactively, with automatic metadata detection and smoke testing.
---

# model-add

Add a new model to the benchmark.

## When to use

When you want to add a model to the benchmark for a specific runtime:
- Invoke with `/model-add`
- Answer the prompts for runtime, model ID, and metadata
- The skill will confirm the model is live-discoverable, create the model card, optionally add to aliases, and validate with bin/smoke

Models no longer need registering in a file: `bin/bench`, `bin/stale`, and
friends discover what's available by querying each runtime's live
`/v1/models` endpoint (or `lms ls` / `ollama list` for lms/ollama). Once a
model is downloaded and the runtime can see it, it's automatically in scope —
this skill's job is the metadata/card/alias/smoke-test side, not registration.

## Implementation

1. Ask user for runtime + modelKey, then auto-detect metadata:
   - Prompt for: Runtime (lms, ollama, mlx, omlx, or mtplx), Model ID / modelKey
   - Auto-detect disk size:
     - For lms: `lms ls --json | jq '.[] | select(.modelKey == "ID") | .diskSize'`
     - For ollama: extract from `ollama list`
   - Parse model name for param count (e.g., "qwen3.6-27b" → 27B, "glm-4.7" → infer)
   - Then ask user ONLY for unknown metadata:
     - Confirm param count if ambiguous
     - Context window (if not in model name)
     - License (check HuggingFace or ask)
     - Optional: short alias for models-aliases.conf

2. Validate — confirm the modelKey is live-discoverable for the runtime:
   - For lms: `lms ls --json | jq -r '.[].modelKey'` contains it; extract diskSize
   - For ollama: `ollama list` contains it
   - For mlx: `curl -fsS http://localhost:8080/v1/models` (server must be running with the model loaded)
   - For omlx: `curl -fsS "$OMLX_BASE_URL/models" | jq -r '.data[].id'` contains it
   - For mtplx: `curl -fsS "$MTPLX_BASE_URL/models" | jq -r '.data[].id'` contains it (server must be running via `mtplx quickstart`)
   - If it's not showing up, stop and investigate with the user before continuing — do not fabricate metadata for a model the runtime can't see yet

3. Create model card:
   - Generate docs/models/<org>--<model>.md
   - Use the template in docs/models/mistralai--devstral-small-2-2512.md as reference
   - Include placeholders for other runtimes (marked with —)
   - Populate Metadata table, Download section, Smoke test section

4. Update models-aliases.conf (optional):
   - Ask if they want a short alias
   - If yes: determine the right insertion point and add tab-separated entry
   - If model is single-runtime, leave the other runtimes' id columns as —

5. Validate with bin/smoke:
   - Run: `bin/smoke --runtime <runtime> --model <modelKey> --dry-run` first
   - Then: `bin/smoke --runtime <runtime> --model <modelKey>` to prove wiring works
   - Report results (PASS/PARTIAL/FAIL)

6. Update project memory:
   - Record the added model(s) in project memory for future context

## Notes

- One runtime per model addition (they may load the same model across runtimes later)
- Model card is documented for one runtime, with structure for future cross-runtime comparison
- If smoke test fails, do NOT write the model card or alias yet — investigate the failure with the user first
- After successful addition: prompt suggests running `bin/stale --runtime <rt>` to see the model in a worklist
