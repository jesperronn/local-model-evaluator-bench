---
name: project-benchmark-status
description: "Which adapters are fully benchmarked vs smoke-only vs not feasible — read from docs/tools/*.md Status sections"
metadata:
  type: project
---

Tool benchmark status is authoritative in `docs/tools/<name>.md` Status sections. Query:
```bash
grep -l "under-evaluation\|broken\|not evaluated\|not feasible" docs/tools/*.md | xargs -I{} basename {} .md
```

**How to find what's not yet fully benchmarked:** read Status from the tool docs — don't derive it from results CSV files.

**Why:** the original question "which tools haven't been scored?" was answered by grepping result dirs, not docs. The docs were missing tool pages entirely for cline, interpreter, pi, and goose. The fix was to add tool docs so future queries read from markdown.

**How to apply:** when asked what's tested or what's missing, grep the docs/tools/*.md Status sections first.

---

**Workarounds policy (2026-06-25):** score `(tool, model)` pairs *with* a working shim/wrapper, never as-shipped — but record what was needed on a `Workarounds needed:` line in every tool/model card. See [docs/SCORING.md](../docs/SCORING.md#workarounds-and-fairness).

First recorded workaround: **pi `edit` + qwen3-coder** — flat `<parameter=NAME>` XML tool calls can't encode pi's nested `edits:[{oldText,newText}]` param; the parser mangles it; model falls back to `write`. **CORRECTION (2026-06-25):** this is PATH-dependent, *not* structural to the model. The original jirafs handoff said "structurally CANNOT encode" — a captured bench trace falsifies that: qwen3-coder-30b emits a clean nested `edit` via `pi --provider lmstudio` (structured tool_calls). The mangling only occurs on a `<parameter=>` prompt-template path. Live re-confirm on current LM Studio build is still pending (deferred for RAM). Trace tools: `bin/trace-edit`, `bin/trace-tool-calls`. Recovery shim documented in [docs/tools/pi.md](../docs/tools/pi.md). **Done (2026-06-25):** shim moved into the repo at `bin/pi-patch-edit-shim` and applied automatically (idempotent, non-fatal warn) by all pi + caveman adapters before each run; `llmrun` inherits it via the repo's adapters. The `dotfiles/bin/` copy is now redundant.

**Key gotcha — score-blind:** `smoke-01-edit-file` does NOT detect this failure. pi/caveman + qwen3-coder-30b score 1.00 with or without the shim because the model recovers via the `write` tool. So caveman's 100% is consistent with the failure existing, and breadth checks across other Hermes models can't be done by pass-rate — only by inspecting tool-call traces for the mangled `<parameter=oldText>` blob, or via a multi-edit case where `write` fallback is costlier.
