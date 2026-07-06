---
title: "gemma4-claude (Custom)"
model_key: "gemma4-claude"
family: "Gemma 4"
params_total: "26B"
params_active: "4B"
quantization: "MLX (Custom modelfile)"
disk_size: "~12-14 GB"
context: "128k (custom, vs 4k default)"
status: "keep"
recommended_for: ["64gb"]
tier: "64gb"
best_adapter: "pi"
accuracy: "86.8%"
speed_avg: "~113s per case"
added: "2026-07-06"
last_run: "2026-07-06"
---

# gemma4-claude (Custom Variant)

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 86.8% (pi) |
| **Speed (avg)** | ~113s per case |
| **Best adapter** | pi (86.8%) > aider (79.4%) |
| **Recommended for** | agentic workflows with 128K context window |
| **Status** | keep (experimental) |

> **Purpose:** Custom variant with enlarged context window (128K vs 4K default) + temperature 0.2 for stable tool-call JSON (qwen2.5-coder targeted tuning).

## Metadata

| Field | Value |
|--------|-------|
| **Ollama model** | `gemma4-claude` |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active) |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | ~12-14 GB |
| **Context window** | 128K (custom, vs 4K standard) |
| **Temperature** | 0.2 (custom, for stable tool calls) |
| **Build** | `bin/setup-ollama-modelfile gemma4-claude` |
| **Quantization** | MLX (Ollama default) |
| **Added** | 2026-07-06 (overnight restart, fast adapters only) |
| **Last run** | 2026-07-06 (run `20260706-000913`) |
| **Doc updated** | 2026-07-06 |

## Results summary (2026-07-06 Overnight)

Restarted with fast adapters only (aider + pi) after original batch was interrupted.

| Adapter | Tests | Pass % | Speed | Notes |
|---------|-------|--------|-------|-------|
| **pi** | 33/38 | **86.8%** | 129s | Best on this model |
| **aider** | 27/34 | **79.4%** | 98s | Decent, slightly slower than pi |

**Overall:** 60/72 (83.3%)

## Custom vs Standard Comparison

| Feature | gemma4-claude (Custom) | gemma4:26b-mlx (Standard) |
|---------|:---:|:---:|
| Context | 128K | 4K |
| Temperature | 0.2 | default |
| pi accuracy | 86.8% | 82.4% |
| pi speed | 129s | 138s |
| Purpose | Agentic (tool-calls) | General coding |

**Result:** Custom variant slightly *better* on pi (86.8% vs 82.4%), same/faster speed (129s vs 138s).

## Key findings

1. **Larger context helps pi** — 86.8% vs 82.4% on standard variant (4.4% lift).
2. **Lower temperature good for tool calls** — 0.2 makes JSON generation more stable (designed for qwen2.5 but helps across models).
3. **Both aider + pi work** — Good fallback if pi fails; aider at 79.4% is acceptable.

## Deferred testing

- [ ] hermes + gemma4-claude (was in original batch before interrupt)
- [ ] codex + gemma4-claude
- [ ] openhands + gemma4-claude

## Recommendation

**Use for:** Agentic workflows where you need:
- Tool-call stability (temperature 0.2)
- Large context window (128K for multifile analysis)
- Good balance (86.8% accuracy, reasonable speed)

**vs gemma4:26b-mlx:** Custom variant wins for agentic use; standard variant faster if context < 4K is acceptable.

## Status

**active** — 86.8% on pi, shows promise. Custom tuning (context + temperature) provides measurable improvement over standard variant.
