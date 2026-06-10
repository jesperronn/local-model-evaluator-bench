# Cline (VS Code extension)

Category: [IDE extensions / plugins](README.md) · See also: [SETUP.md §4](../SETUP.md#4-editor-extensions-same-lm-studio-server) · [tools/codex.md](../tools/codex.md) · [tools/opencode.md](../tools/opencode.md)

> **All model recommendations on this page are heuristic.** No case has been run
> through Cline and graded yet (see [Status](#status)). The judgements are
> transferred from the CLI adapters that behave most like Cline — **codex**,
> **opencode**, and **caveman** (structured tool-calls + multi-turn agentic
> loops). When direct Cline runs exist, replace the heuristic table with
> measured results and drop the disclaimer.

## Metadata

| Field | Value |
|-------|-------|
| **Extension** | Cline (`saoudrizwan.claude-dev`) |
| **IDE** | VS Code |
| **Version** | <!-- TODO: fill from VS Code Extensions pane --> |
| **How it connects** | API Provider = **OpenAI Compatible**, Base URL `http://localhost:1234/v1`, any API key, Model ID = the id from `bin/doctor` |
| **Edit style** | Multi-turn agentic loop; XML-tagged tool calls (`write_to_file`, `replace_in_file`, `execute_command`, `read_file`, …). `replace_in_file` uses SEARCH/REPLACE diff blocks. |
| **Last reviewed** | 2026-06-10 |

## Recommended connection settings

Matches the Settings panel fields shown in Cline's *OpenAI Compatible* provider:

| Field | Recommended | Why |
|-------|-------------|-----|
| **API Provider** | `OpenAI Compatible` | LM Studio speaks the OpenAI API; Cline's built-in "LM Studio" preset also works and auto-lists loaded models. |
| **Base URL** | `http://localhost:1234/v1` | Same endpoint every adapter uses (`config.sh` → `LMS_BASE_URL`). |
| **API Key** | any non-empty string | LM Studio ignores it but the field must be set. |
| **Model ID** | exact id from `bin/doctor` | Must match `/v1/models`; see the model-id caveat in [SETUP.md](../SETUP.md#1-lm-studio). |
| **Context Window Size** | the model's native window (e.g. `131072` for Qwen3) **and** load the model in LM Studio with ≥ **32K** context | This field only tells Cline how much it *may* use. The real limit is LM Studio's load-time context length — set both. Cline's system prompt is large (≈10K+ tokens before any code), so a small load-time context truncates fast. On a 128 GB rig the extra KV cache is cheap; prefer 64K+. |
| **Max Output Tokens** | `-1` (model default); set `8192` only if you see truncated edits | LM Studio honours the model default at `-1`. A hard cap helps only when a runaway generation needs bounding. |
| **Temperature** | `0` | Deterministic edits; correct for code. |
| **Enable R1 messages format** | **off** | Only for DeepSeek-R1-style models. None of the models in this suite are R1. |
| **Supports Images** | per model | On for Gemma 4 (multimodal) if you want screenshot-to-code; off / irrelevant for the Qwen3-Coder text models. |
| **Prompt Caching** | n/a | Not supported over the LM Studio OpenAI endpoint. |

**Pre-load for context + concurrency.** Cline hits the endpoint and lets LM
Studio JIT-load the model — which uses the *default* load config, not any CLI
flag. To guarantee a large context **and** `--parallel` (needed if you run
several editor windows / agents against one model at once), **pre-load
explicitly** before opening VS Code:
`lms load <id> --context-length 65536 --parallel 4 --ttl 3600 --yes`
(or the `lms-serve` dotfiles wrapper). An already-loaded instance is reused. Full
explanation in [SETUP.md → Context length & concurrency](../SETUP.md#context-length--concurrency--persistent-defaults).

**LM Studio side:** if the loaded model emits reasoning (`<think>` blocks),
disable it — Cline parses XML-tagged tool calls and stray reasoning tags confuse
the parser. Turn reasoning off in LM Studio's model settings, or append a
`/no_think`-style directive to the system prompt for models that support it.

## Why Cline is different from the CLI adapters

Cline is not just another OpenAI client — it is the **most demanding** harness on
this list for a *local* model, for three reasons. The extension's own UI warns:
*"Cline uses complex prompts and works best with Claude models. Less capable
models may not work as expected."* Take that literally for small local models.

1. **Very large system prompt.** Cline ships a long instruction block (tool
   schemas, formatting rules, examples) on every turn. Models with weak
   long-context instruction-following degrade or ignore the tool format.
2. **Strict XML tool-call format.** Edits happen through `write_to_file` /
   `replace_in_file` tool calls wrapped in XML tags. A model that emits prose,
   markdown fences, or malformed tags produces no edit — the same *format-
   failure* class seen with aider's diff blocks and codex's tool calls.
3. **SEARCH/REPLACE diffs are quant-sensitive.** `replace_in_file` requires the
   SEARCH block to match the file **byte-for-byte**. Reproducing exact
   whitespace and identifiers is exactly what degrades first under aggressive
   quantization (see [SETUP.md → quantization](../SETUP.md#which-quantization--accuracy-vs-speed-vs-context)).
   On smaller/4-bit models expect more "diff did not match" retries.

**Closest CLI analogues:** codex and opencode (autonomous file discovery,
multi-turn tool-calling) and caveman (reliable structured edits). A model's
score on those three is the best available predictor for Cline. A model that is
strong on aider but weak on codex/opencode is a **poor** Cline bet — aider gets
explicit file hints and a simpler format that Cline does not replicate.

## Heuristic model evaluation

Ranked by predicted Cline fitness. The **transfer basis** column cites the
measured CLI result the judgement is inferred from (from
[LEADERBOARD.md](../../LEADERBOARD.md)). **None of these are Cline-measured.**

| Model | Predicted fit | Transfer basis (measured on CLIs) | Notes for Cline |
|-------|---------------|-----------------------------------|-----------------|
| `qwen/qwen3-coder-30b` | **Best default** | codex 100%, caveman 100%, opencode 97% | Top overall (79.6%). Strong tool-calling + multi-file. The safe first choice on the 128 GB rig. |
| `qwen/qwen3.6-35b-a3b` | **Excellent** | codex 100%, opencode 100%, caveman 100% | A3B → fast for its size. Ties coder-30b on the Cline-like adapters; pick on speed/feel. |
| `google/gemma-4-26b-a4b-qat` | **Good (Gemma option)** | opencode 100%, caveman 100%, codex 88% | Best Gemma for Cline. The codex dip (88%) hints at some tool-format friction — watch for retries on multi-file cases. |
| `qwen/qwen3.5-9b` | **Usable, variable** | codex 100% but opencode 67.6% | The codex↔opencode split is a warning: tool-format robustness is inconsistent. Likely workable for single-file edits, shakier on Cline's multi-file `replace_in_file`. |
| `qwen/qwen3-coder-next` | **⚠️ Caution** | codex 100% but **opencode broken (7.1%, error(1))** | Excellent on codex, but the opencode breakage is the red flag *because Cline is opencode-like*. Until the cause is known, treat as risky in Cline. See [model page](../models/qwen--qwen3-coder-next.md). |
| `google/gemma-4-e4b` / `e4b-qat` | **Marginal** | codex 50% / 58%, opencode 73% / 76% | Small Gemmas hit Cline's "less capable models may not work as expected" warning. May complete simple single-file tasks; expect format failures on anything multi-file or self-verify. |
| `google/gemma-4-e2b` / `e2b-qat` | **Not recommended** | codex 41% / 43% | Too small for Cline's prompt + format load. Fine for quick chat, not agentic editing. |

### Placeholders — not decently tested

These lack trustworthy CLI data to transfer from, so no Cline heuristic is
offered yet. Fill in after they have real CLI results (or a direct Cline run).

| Model | Why no recommendation | Trigger to revisit |
|-------|----------------------|--------------------|
| `google/gemma-4-12b` (non-QAT) | CLI data is mostly load/format failures (13.6% overall) — not a real capability signal. | Re-bench once it loads cleanly; compare to the `-qat` variant. |
| `google/gemma-4-31b` / `gemma-4-31b-qat` | Only 7.1% across every adapter — these are loading/wiring failures, not measured ability. | Re-bench after the load issue is fixed; until then, no Cline call. |
| `google/gemma-4-26b-a4b` (non-QAT) | Not downloaded / not benchmarked yet (commented in `models.txt`). | Download in LM Studio, bench on codex+opencode, then transfer. |
| `qwen/qwen3.6-35b-a3b` @ other quants | Only one quant measured; Cline's SEARCH/REPLACE is quant-sensitive. | Head-to-head a 2nd bit-level on a multi-file case (`bin/bench --models a,b`). |
| _Cline-measured results, any model_ | <!-- TODO --> No case has been graded through Cline yet. | Run the manual procedure below and record outcomes here. |

## Manual evaluation procedure

Cline isn't in the automated matrix, so grade it by hand using each case's own
grader (full version in [SETUP.md §4](../SETUP.md#4-editor-extensions-same-lm-studio-server)):

1. Load the target model in LM Studio with ≥ 32K context (`lms load <id> --context-length 32768`).
2. In VS Code, open a **copy** of `cases/<id>/workdir/` and point Cline at it.
3. Paste the case's `cases/<id>/task.md` prompt; let Cline run its loop to completion.
4. Grade the edited copy:
   ```bash
   cd <your-edited-copy-of cases/<id>/workdir>
   CASE_DIR=/abs/path/to/cases/<id> REPO_ROOT=/abs/path/to/repo \
     bash "$CASE_DIR/check/run.sh"        # prints RESULT pass=N total=N
   ```
5. Record pass/total, wall-clock feel, and any **format failures** (no edit
   applied, malformed tool call, SEARCH block didn't match) — those are the
   Cline-specific signal that doesn't show up in CLI numbers.

Good starter cases: `js-01-slugify-bug` (single-file), `js-04-multifile-rename`
(stresses `replace_in_file` across files), `js-06-lint-and-test` (stresses the
self-verify loop — does Cline run the tests and iterate?).

## Status

**heuristic — not yet measured.** Recommendations are inferred from codex /
opencode / caveman results, the CLI adapters closest to Cline's tool-calling
agentic loop. Highest-confidence default: `qwen/qwen3-coder-30b`. Replace this
section with measured pass/total once the manual procedure has been run on a few
cases. First Cline run is the trigger to update.
