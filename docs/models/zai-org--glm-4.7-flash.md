# zai-org/glm-4.7-flash

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `zai-org/glm-4.7-flash` (confirm via `lms ls --json` after download) |
| **Family / arch** | GLM-4.7 (Zhipu AI), dense transformer |
| **Parameter count** | 30B |
| **Context window** | 128K tokens |
| **License** | <!-- TODO — verify from HuggingFace card --> |
| **Disk size** | 24.36 GB (GGUF, lmstudio-community) |
| **Added** | 2026-06-28 |
| **Last run** | 2026-06-28 aider (stalled, incomplete) |
| **Doc updated** | 2026-06-28 |
| **Workarounds needed** | Increase watchdog timeout to 300s+ for agentic adapters (aider, swe-agent), or exclude from agentic workflows |

## Download

```bash
lms get zai-org/glm-4.7-flash
# confirm the exact modelKey:
lms ls --json | jq -r '.[].modelKey' | grep -i glm
```

GGUF is published by the LM Studio community team. Fits a 32GB Mac.

## Smoke test

Run once to validate adapter wiring:
```bash
bin/smoke --runtime lms --model zai-org/glm-4.7-flash
```

Expected: PASS on all adapters.

## Performance notes

**⚠️ CRITICAL: Too slow for agentic tasks.** Generation stalls exceed 120s, causing watchdog timeouts. Task: js-02-debounce-feature (aider + zai-org/glm-4.7-flash) — took 593s total with watchdog abort during code generation. Not viable for tasks requiring real-time interaction (e.g., aider, mini-swe-agent).

## Observations across runs

- 2026-06-28 (initial): smoke test passed; model performs [pending full bench run]
- 2026-06-28 (aider trial): **STALLED** — js-02-debounce-feature test. Watchdog abort at 120s during LMS code generation. Completed 3/4 tests (59.3s stall, 593s total). Model generates too slowly for agentic workflow. Recommend: remove from aider rotation or increase watchdog timeout substantially.
