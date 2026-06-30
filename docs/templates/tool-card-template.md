# {Tool name}

<!-- Replace {Tool name} with the agent/tool display name, e.g. Cline, Goose, Aider -->

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | <!-- e.g. 100% on qwen3.6-35b-a3b (lms) --> |
| **Speed (avg)** | <!-- e.g. ~54s per case --> |
| **Best model** | <!-- e.g. qwen/qwen3.6-35b-a3b (~54s) — lms --> |
| **Recommended for** | <!-- e.g. autonomous multi-file edits, self-verify loops --> |
| **Status** | <!-- stable / experimental / broken --> |

> **Rule:** when two tools have equal accuracy, prefer the faster one.
> Speed column must always be filled — "unknown" is not acceptable for an evaluated tool.

---

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | <!-- display name --> |
| **CLI command** | <!-- e.g. `cline`, `aider`, `goose` --> |
| **Version** | <!-- e.g. 1.0.0, or "latest (pnpm store binary)" --> |
| **Adapter script** | <!-- [`adapters/name.sh`](../../adapters/name.sh) --> |
| **How it connects** | <!-- e.g. OpenAI-compatible API via `--baseurl`; provider config written per run --> |
| **Last reviewed** | <!-- YYYY-MM-DD --> |

---

## Edit mechanism

- **Format:** <!-- e.g. tool calls (JSON), search-replace blocks, unified diff, whole-file rewrite -->
- **File targeting:** <!-- e.g. autonomous via read/list tools; explicit path arg; git-diff based -->
- **Multi-file edits:** <!-- e.g. native via tool-call loop; limited; not supported -->
- **Self-verify / iteration:** <!-- e.g. runs tests via execute_command and loops; single-pass only -->

---

## Results by model

> Accuracy = fraction of assertion points earned. Speed = median wall-clock time per case.
> Sorted by accuracy desc, then speed asc (faster wins on ties).

| Model | Accuracy | Speed (avg) | Runtime | Notes |
|-------|:--------:|:-----------:|---------|-------|
| <!-- model key --> | <!-- 38/38 (100%) --> | <!-- ~54s --> | <!-- lms --> | |

---

## Per-case breakdown

<!-- Only include if per-case detail adds insight beyond the summary table. -->

| Case | Score | Time | Status | Notes |
|------|------:|-----:|--------|-------|
| <!-- bash-01-topwords --> | <!-- 4/4 --> | <!-- 296s --> | <!-- ok --> | |
| **Total** | | | | |

---

## Adapter setup

| Flag | Value | Reason |
|------|-------|--------|
| <!-- --data-dir --> | <!-- $DATA_DIR --> | <!-- isolates state from user install --> |
| <!-- --model --> | <!-- "$MODEL_ID" --> | <!-- runtime model override --> |

---

## Failure modes

<!-- Only document repeatable failures, not one-off flakiness. -->

<!-- Example:
**Short title — root cause:**
Description. Workaround or fix if known.
-->

---

## Known issues

<!-- Open issues as of last review. Remove when resolved; move to Observations. -->

---

## Observations across runs

<!-- Append a section per run batch. Newest first. -->

### {YYYY-MM-DD} — {runtime} (run `{run-id}`)

<!-- What changed, what was notable. Keep to 3–5 sentences. -->

---

## Status

**{stable / experimental / broken}** — one-sentence rationale. Cross-link model and runtime pages where relevant.
