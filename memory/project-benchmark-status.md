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
