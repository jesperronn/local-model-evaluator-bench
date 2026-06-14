---
name: feedback-timeout-300s
description: "300s per-case timeout is the intentional bar — don't raise it; slow = not good enough"
metadata:
  type: feedback
---

Never raise the bench timeout above 300s (the default). A model that can't solve a case in 5 minutes is not fast enough to be useful.

**Why:** The project goal is finding fast AND accurate agentic editing workflows. A 5-minute timeout is already a generous ceiling — any model that needs more time is disqualified by design, not by the harness.

**How to apply:** Do not pass `--timeout 600` or any value above 300 to `bin/bench`. When a case hits 300s, record it as a failure and move on. Do not retry with a longer timeout.
