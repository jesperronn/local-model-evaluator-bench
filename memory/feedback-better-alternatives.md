---
name: feedback-better-alternatives
description: Always include a "Better alternatives" section when writing or updating tool or model eval pages
metadata:
  type: feedback
---

Always write a "Better alternatives" section in every tool and model eval page (`docs/tools/*.md`, `docs/models/*.md`).

**Why:** Eval pages should be actionable for someone choosing between tools or models, not just descriptive. Without this section the reader has to cross-reference every other page manually.

**How to apply:** Add the section under Required sections (before Known issues). Name concrete alternatives with one sentence each explaining when they win. Also note any niche where the evaluated tool/model clearly leads. The structure is codified in [[TOOL-EVAL-REQUIREMENTS]] and [[MODEL-EVAL-REQUIREMENTS]].
