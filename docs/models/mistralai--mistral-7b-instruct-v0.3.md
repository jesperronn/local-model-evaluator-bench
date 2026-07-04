# mistralai/mistral-7b-instruct-v0.3

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | N/A (incompatible) |
| **Speed (avg)** | N/A |
| **Best adapter** | None |
| **Recommended for** | Not suitable for agentic work |
| **Status** | avoid — prompt template incompatibility |

## Metadata

| Field | Value |
|-------|-------|
| **Status** | AVOID — Jinja2 prompt template incompatibility with agentic adapters |
| **Model key** | `mistralai/mistral-7b-instruct-v0.3` |
| **Family / arch** | Mistral, dense, 7B (Llama architecture) |
| **Parameter count** | 7B |
| **Disk size** | ~4.37 GB (GGUF) |
| **Added** | 2026-07-04 |
| **Last run** | 2026-07-04 |
| **Doc updated** | 2026-07-04 |

## Known issues

### Critical: Prompt template incompatibility

**Error:** `Error rendering prompt with jinja template: "Only user and assistant roles are supported!"`

**Root cause:** This model's Jinja2 prompt template only supports `user` and `assistant` roles, but does not support the `system` role. Agentic adapters (aider, cline, hermes, pi, opencode, etc.) require multi-role prompting that includes system instructions for tool definitions and agent context.

**Adapters affected:**
- **aider**: fails on all cases (smoke and bench)
- **cline**: fails on all cases (smoke and bench)
- **hermes, opencode, pi**: likely affected (untested in detail)

**Evidence:**
- Smoke test with `--agent aider,cline`: all 3 cases fail (smoke-00-hello, smoke-01-edit-file, smoke-02-numbers)
- Error occurs during prompt template rendering, before model inference
- This is a LM Studio/model configuration issue, not a bench harness issue

## Why it fails

The model card in LM Studio specifies a Jinja2 template like:

```jinja
{% for message in messages %}
{% if message.role == "user" %}
[INST] {{ message.content }} [/INST]
{% elif message.role == "assistant" %}
{{ message.content }}
{% endif %}
{% endfor %}
```

When adapters try to send a `system` role message (for tool definitions or agent context), the template has no handler for it and the error fires.

## Workaround

Edit the model's Jinja2 template in LM Studio:
1. **My Models** → select the model → **Prompt Template**
2. Add a system role handler:
   ```jinja
   {% if message.role == "system" %}
   {{ message.content }}
   {% endif %}
   ```
3. Test with `bin/smoke --model mistralai/mistral-7b-instruct-v0.3 --agent aider,cline`

## Better alternatives

**For agentic coding on 7B scale:**
- **qwen/qwen2.5-coder-7b** — 4.30 GB, passes all smoke tests with aider + cline, code-specialized
- **qwen/qwen3.5-9b** — 5.6 GB, passes all smoke tests with aider + cline, stronger general reasoning

**For Mistral if you need it:**
- **mistralai/mistral-nemo-instruct-2407** — 12B, properly templated for multi-role prompting (verify with smoke test)
- **lmstudio-community/Mistral-7B-Instruct-v0.2-GGUF** — older variant; check prompt template before use

## Status

**avoid** — Prompt template incompatible with agentic adapters. Do not use for benchmarking unless the template is patched. Qwen 2.5 Coder or Qwen 3.5 are better alternatives at comparable size with proven compatibility.

## See also

- [Prompt template issue in LM Studio docs](https://lmstudio.ai/)
- [LEADERBOARD.md — Models to avoid](../../LEADERBOARD.md#models-to-avoid)
- Related: `mistralai/devstral-small-2-2512` (24B, better agentic support)
