# model-add

Add a new model to the benchmark.

## When to use

When you want to add a model to the benchmark for a specific runtime:
- Invoke with `/model-add`
- Answer the prompts for runtime, model ID, and metadata
- The skill will insert into models.txt, create the model card, optionally add to aliases, and validate with bin/smoke

## Implementation

1. Ask user for runtime + modelKey, then auto-detect metadata:
   - Prompt for: Runtime (lms, mlx, or ollama), Model ID / modelKey
   - Auto-detect disk size:
     - For lms: `lms ls --json | jq '.[] | select(.modelKey == "ID") | .diskSize'`
     - For ollama: extract from `ollama list`
   - Parse model name for param count (e.g., "qwen3.6-27b" → 27B, "glm-4.7" → infer)
   - Then ask user ONLY for unknown metadata:
     - Confirm param count if ambiguous
     - Context window (if not in model name)
     - License (check HuggingFace or ask)
     - Optional: short alias for models-aliases.conf

2. Validate:
   - Confirm the modelKey exists in the runtime's system
     - For lms: `lms ls --json | jq -r '.[].modelKey'` contains it; extract diskSize
     - For ollama: `ollama list` contains it
     - For mlx: check ~/.lmstudio/models/ or equivalent

3. Determine placement in models.txt:
   - Read models.txt
   - Parse existing param counts (from comments)
   - Find the right insertion point (ordered smallest → largest)
   - Insert with formatted comment (matching existing style)

4. Create model card:
   - Generate docs/models/<org>--<model>.md
   - Use the template in docs/models/mistralai--devstral-small-2-2512.md as reference
   - Include placeholders for other runtimes (marked with —)
   - Populate Metadata table, Download section, Smoke test section

5. Update models-aliases.conf (optional):
   - Ask if they want a short alias
   - If yes: determine the right insertion point and add tab-separated entry
   - If model is single-runtime, leave mlx_id/ollama_id as —

6. Validate with bin/smoke:
   - Run: `bin/smoke --runtime <runtime> --model <modelKey> --dry-run` first
   - Then: `bin/smoke --runtime <runtime> --model <modelKey>` to prove wiring works
   - Report results (PASS/PARTIAL/FAIL)

7. Update project memory:
   - Record the added model(s) in project memory for future context

## Notes

- One runtime per model addition (they may load the same model across runtimes later)
- Model card is documented for one runtime, with structure for future cross-runtime comparison
- If smoke test fails, do NOT edit models.txt yet — investigate the failure with the user first
- After successful addition: prompt suggests running `bin/stale --runtime <rt>` to see the model in a worklist
