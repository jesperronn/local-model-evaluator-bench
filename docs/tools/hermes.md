# hermes

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Hermes Agent |
| **CLI command** | `hermes` |
| **Version** | v0.16.0 (2026.6.5) |
| **Adapter script** | [`adapters/hermes.sh`](../../adapters/hermes.sh) |
| **How it connects** | Built-in `lmstudio` provider, configured in `~/.hermes/config.yaml` (`provider: lmstudio`, `base_url: http://127.0.0.1:1234/v1`). Approvals handled by a "smart guardian" LLM running locally. |
| **Last reviewed** | 2026-06-09 |

## Edit mechanism

- **Format:** hermes uses a tool-call based agent loop. With `-t file,terminal`, it can write files and run shell commands.
- **File targeting:** autonomous CWD discovery via the file toolset.
- **Multi-file edits:** tool-calling architecture supports it in theory. In practice, hermes produces no meaningful edits in the current bench configuration.

## Iteration / self-verify behaviour

hermes is configured to iterate via its smart guardian approval system. For self-verify cases, the model should run tests and iterate. However, since hermes currently fails all cases before producing any edits, self-verify capability cannot be assessed from bench data.

## Failure modes

**Consistent error(1) on all models (primary failure mode):** hermes exits with error(1) in 3–15s on every model and every case, except for js-01-slugify-bug which produces 2/4 across all models. The 3–15s timing suggests hermes reaches the model but something in the approval pipeline or tool execution fails before any file edit is committed.

The js-01 exception (2/4) is notable — hermes apparently produces a partially correct solution for js-01 on every model, suggesting it can do single-file edits when the task is simple enough. The 2/4 score means it passes sub-tests 1–2 (basic slug conversion) but fails 3–4 (edge cases like consecutive hyphens).

**Smart guardian interaction:** the adapter uses `approvals.mode: smart` in the hermes config. If the guardian LLM (which uses the same local model) is consuming tokens and competing with the primary model, or if the guardian denies the file-write tool call, edits would fail silently. This is the most likely cause of the systematic error(1) failures.

**Timing pattern on gemma-4-12b (ok, 11–15s):** hermes shows ok status (not error) on gemma-4-12b but still scores near-zero with 11–15s per case. This is the only model where hermes returns ok — it suggests hermes can reach the model but produces no valid edits. The smart guardian may be approving but the model's tool calls are malformed.

## Adapter flags and their rationale

| Flag | Reason |
|------|--------|
| `--provider lmstudio` | Selects the pre-configured LM Studio provider |
| `-m "$MODEL_ID"` | Specifies the model key |
| `-t file,terminal` | Enables file-edit and shell tool sets (without this, hermes only chats) |
| `-z "$PROMPT"` | Non-interactive prompt delivery |

## Known issues

**Systematic error(1) on all models:** hermes contributes no useful benchmark data in its current configuration. The smart guardian approval system appears to be blocking or failing on file-write operations. **This is the primary blocker.**

Suggested investigation:
1. Run `hermes` manually on a simple task in a sandbox and inspect the guardian decision log.
2. Try `--yolo` to bypass the guardian entirely and determine whether the issue is in the approval step or elsewhere.
3. Check `~/.hermes/config.yaml` — verify `terminal.backend: local` is set, and that `approvals.mode` and `approval.provider: auto` are correctly configured.

**No `--yolo` in adapter:** the adapter deliberately avoids `--yolo` in favour of the smart guardian. For benchmarking purposes, `--yolo` may be necessary to get any signal, then the guardian can be re-enabled once the base failure mode is understood.

## Status

**broken** — hermes produces no useful data for any model. The systematic error(1) failures suggest a configuration or guardian approval issue rather than an inherent tool limitation. Fix requires reproducing the failure manually and debugging the guardian pipeline. Once fixed, re-run with all models to get a baseline.
