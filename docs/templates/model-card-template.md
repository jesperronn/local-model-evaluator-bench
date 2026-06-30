# {model-key}

<!-- Replace {model-key} with the exact LMS/Ollama model identifier, e.g. qwen/qwen3.6-35b-a3b -->

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | <!-- e.g. 100% across working adapters, or 94% avg --> |
| **Speed (avg)** | <!-- e.g. ~48s per case (lms, 3B active) --> |
| **Best adapter** | <!-- e.g. codex — fastest; cline — most reliable --> |
| **Recommended for** | <!-- e.g. general agentic coding, multi-file edits --> |
| **Status** | <!-- keep / watch / drop --> |

> **Rule:** when two models have equal accuracy, prefer the faster one.
> Speed column must always be filled — "unknown" is not acceptable for an evaluated model.

---

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | <!-- exact identifier as used in adapters/bench --> |
| **Family / arch** | <!-- e.g. Qwen3.6, MoE --> |
| **Parameter count** | <!-- e.g. 35B total, 3B active --> |
| **Quantization** | <!-- e.g. GGUF Q4_K_M, MLX 6-bit, mxfp8 --> |
| **Disk size** | <!-- e.g. 18 GB --> |
| **Context window** | <!-- e.g. 128k --> |
| **Added** | <!-- YYYY-MM-DD --> |
| **Last run** | <!-- YYYY-MM-DD (run ID) --> |
| **Doc updated** | <!-- YYYY-MM-DD --> |

---

## Results summary

> Accuracy = fraction of assertion points earned. Speed = median wall-clock time per case across all passing runs.
> Both are measured, not inferred.

| Adapter | Accuracy | Speed (avg) | Runtime | Notes |
|---------|:--------:|:-----------:|---------|-------|
| <!-- adapter --> | <!-- 38/38 (100%) --> | <!-- ~54s --> | <!-- lms --> | <!-- e.g. all cases pass --> |

**Working adapters total:** <!-- e.g. 9/11 -->  
**Overall (incl. broken adapters):** <!-- e.g. 366/406 (90%) -->

---

## Timing observations

<!-- One paragraph or bullet list. Cover: fastest adapter, slowest adapter, per-case outliers, and any
     runtime-specific speed differences. Always mention absolute numbers (seconds), not just relative. -->

- **Fastest adapter:** <!-- e.g. codex: 19–74s, avg ~40s -->
- **Slowest adapter:** <!-- e.g. cline: 31–300s, avg ~160s -->
- **Slow cases:** <!-- e.g. js-06 lint self-verify ~300s on most adapters; bash-01 ~130s on aider -->
- **Runtime note:** <!-- e.g. MLX variant 3.3× faster than GGUF on Apple Silicon -->

---

## Failure patterns

<!-- Only document repeatable failures. Skip if all adapters pass cleanly. -->

<!-- Example:
**adapter-name — brief cause:**
Short description of what fails and why. Link to adapter page if the failure is adapter-specific.
-->

---

## Comparison within family

<!-- Compare this model to the closest sibling. Focus on accuracy vs speed trade-off. -->

| Model | Accuracy | Speed (avg) | Recommended over |
|-------|:--------:|:-----------:|-----------------|
| this model | | | |
| closest sibling | | | |

<!-- Conclusion: which to prefer, and under what conditions (hardware, task type, latency budget). -->

---

## Observations across runs

<!-- Append a section per run batch. Newest first. -->

### {YYYY-MM-DD} — {runtime} (run `{run-id}`)

<!-- What changed, what was notable. Keep to 3–5 sentences. -->

---

## Status

**{keep / watch / drop}** — one-sentence rationale. Cross-link sibling model pages if directly comparable.
