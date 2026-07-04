# mistralai/mistral-nemo-instruct-2407

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 16.7% (smoke tests only) |
| **Speed (avg)** | ~20s per case |
| **Best adapter** | aider (67%), goose (67%) |
| **Recommended for** | Not recommended |
| **Status** | avoid — tool-call incompatibilities |

## Metadata

| Field | Value |
|-------|-------|
| **Status** | AVOID — Tool-call template incompatibilities with agentic adapters |
| **Model key** | `mistralai/mistral-nemo-instruct-2407` |
| **Family / arch** | Mistral, dense, 12B (Llama architecture) |
| **Parameter count** | 12B |
| **Disk size** | ~7.48 GB (GGUF) |
| **Context window** | 128K |
| **Added** | 2026-07-04 |
| **Last run** | 2026-07-04 (smoke tests) |
| **Doc updated** | 2026-07-04 |

## Results summary

**Smoke test performance: 4/24 cases (16.7%)**

| Adapter | Results | Notes |
|---------|---------|-------|
| aider | 2/3 (67%) | Passes multi-file edits but fails write-from-scratch |
| goose | 2/3 (67%) | Partial success; mixed results across cases |
| pi | 0/3 (0%) | Generates tool calls but doesn't execute them |
| opencode | 0/3 (0%) | "Unexpected server error" (adapter-level issue) |
| interpreter | 0/3 (0%) | Jinja template error on tool call validation |
| hermes | 0/3 (0%) | File write/read failures; path issues |
| cline | 0/3 (0%) | Tool call execution failures |
| nanocoder | 0/3 (0%) | Tool call generation but no execution |

## Known issues

### Critical: Tool-call template validation error

**Interpreter adapter error:**
```
Error rendering prompt with jinja template: "Tool call IDs should be alphanumeric strings with length 9!"
```

The model's Jinja2 prompt template has strict validation on tool call IDs that:
- Requires alphanumeric characters only
- Enforces a minimum length of 9 characters
- Rejects any tool call format that doesn't match this pattern

**Impact:** Breaks interpreter and likely affects other structured tool-call adapters.

### Tool-call execution failures

Several adapters (pi, cline, nanocoder) successfully generate tool calls in their responses, but the calls are not executed. The model appears to produce the right format but in a way that the adapters don't recognize as actionable.

### File I/O issues

Hermes specifically fails on file operations with path errors (e.g., `/root/.hermes-tmp` not found), suggesting sandbox or working directory configuration issues specific to this model.

## Comparison with alternatives

**Phi-4 (15B)** is vastly superior:
- Smoke test score: 66.7% (vs 16.7% for Nemo)
- Pi: 100% pass rate (vs 0% for Nemo)
- Goose: 100% pass rate (vs 67% for Nemo)
- Proper multi-role template support
- Only 1GB larger on disk (7.48GB → ~9GB)

**Qwen 3.5-9b (9B)** is also better for its size:
- Smoke test score: 100% with aider (verified 2026-07-04)
- Smaller footprint (5.57GB)
- Fully compatible with multi-role prompting

## Status

**avoid** — Tool-call template incompatibilities make this model unsuitable for agentic coding tasks. While aider and goose achieve partial success (67%), the widespread failures across pi, cline, interpreter, nanocoder, and hermes indicate systemic issues with how the model formats tool calls and how adapters interpret them.

**Recommendation:** Use **Phi-4 (15B)** instead for 13-14B tier work. It has 4× higher smoke test pass rate and works reliably with most adapters.

## See also

- [microsoft/phi-4](microsoft--phi-4.md) — Recommended alternative for 13-14B tier
- [qwen/qwen3.5-9b](qwen--qwen3.5-9b.md) — Smaller, more reliable alternative
- [Tools and Adapters](../tools/) — Adapter-specific compatibility notes
