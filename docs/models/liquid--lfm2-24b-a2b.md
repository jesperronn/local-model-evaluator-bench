# liquid/lfm2-24b-a2b

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 33% (1/3 smoke cases — only smoke-01-edit-file passed) |
| **Speed (avg)** | measured pending (no working adapter to measure from) |
| **Best adapter** | none — all 12 adapters failed |
| **Recommended for** | nothing — model does not conform to edit format on any adapter |
| **Status** | drop |

> Rule: when two models have equal accuracy, prefer the faster one. Speed must always be filled.

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `liquid/lfm2-24b-a2b` |
| **Family / arch** | Liquid LFM2, MoE (inferred ~24B total, ~2B active from "a2b" suffix) |
| **Parameter count** | ~24B total, ~2B active (inferred from naming convention) |
| **Quantization** | measured pending (no model file found on disk) |
| **Disk size** | measured pending (no model file found on disk) |
| **Context window** | 65536 (from `BENCH_CONTEXT`) |
| **Added** | 2026-07-02 |
| **Last run** | 2026-07-02 (run `20260702-224812`) |
| **Doc updated** | 2026-07-03 |

## Results summary

Smoke-only run (3 cases, 12 adapters, LMS runtime). **No adapter passed all cases.** 1/3 smoke cases passed (smoke-01-edit-file with aider). All 12 adapters failed for this model — see failure patterns below for root causes.

| Adapter | Smoke (0/3) | Smoke-01 edit (0/1) | Smoke-02 numbers (0/1) | Notes |
|---------|:-----------:|:-------------------:|:----------------------:|-------|
| aider | 0/1 | 1/1 | 0/1 | Edit format non-compliance: model outputs markdown code blocks instead of proper edit format. Model writes ```OK``` instead of creating hello.txt. On smoke-02, correctly identifies 5 but outputs as markdown + separate file creation (creates garbage files named "First, let's determine...", "path=numbers.txt"). |
| cline | 0/1 | 0/1 | — | MISS: `_` still present in file (edit not applied) |
| codex | 0/1 | 0/1 | — | stream disconnected during model refresh |
| caveman | 0/1 | 0/1 | — | Adapter not supported on LMS |
| hermes | 0/1 | 0/1 | — | MISS: word 'hello' not found on its own line in greeting.txt |
| interpreter | 0/1 | 0/1 | — | Unknown process id error (expected process not running) |
| opencode | 0/1 | 0/1 | — | MISS: hello.txt not created |
| openhands | 0/1 | 0/1 | — | MISS: hello.txt not created |
| pi | 0/1 | 0/1 | — | MISS: greeting.txt has 1 lines, expected 3 |
| goose | 0/1 | 0/1 | — | MISS: word 'hello' not found on its own line in greeting.txt |
| nanocoder | 0/1 | 0/1 | — | Path-relative file path error, retries fail |
| cn | 0/1 | 0/1 | — | MISS: `_` still present in file |

**Working adapters total:** 0/12
**Overall (incl. broken adapters):** 1/36 (3%)

## Timing observations

No timing data available — no adapter produced a successful run from which to measure speed.

## Failure patterns

**Edit format non-compliance (root cause, all adapters):** The model consistently outputs markdown code blocks (``` ... ```) instead of conforming to the edit format expected by LMS adapters. This is not a per-adapter issue — it is a model-level behavior.

- On smoke-00-hello (aider): model repeats "Ok, I will create a new file named `hello.txt` with the exact content 'OK'" followed by ```OK``` in a code block — 3 reflections allowed, all rejected by aider with "The LLM did not conform to the edit format. No filename provided before ``` in file listing".
- On smoke-01-edit-file (aider): model *does* produce the correct edit content (`start\nhello\nend` inside ```greeting.txt```) and the edit is applied, but it also outputs a separate file listing block that creates a second file named "end".
- On smoke-02-numbers (aider): model correctly identifies 5 as the missing Fibonacci number but outputs the corrected sequence as a markdown code block and then outputs it line-by-line as separate file creations (creates files named "First, let's determine...", "Now, I will create a new `numbers.txt` file with the corrected sequence", "path=numbers.txt").

**Per-adapter failure details (all from edit format root cause):**

- **codex:** `stream disconnected` during model refresh — model may not be loading correctly on LMS.
- **pi:** File created but with 1 line instead of expected 3 — edit format mismatch caused truncated output.
- **interpreter:** "Unknown process id 12345" — model response triggered a process reference that doesn't exist.
- **goose / hermes / opencode / openhands:** All report "MISS" on hello.txt — model never creates the file, only outputs markdown.
- **cline / cn:** `_` still present in numbers.txt — edit not applied due to format mismatch.
- **nanocoder:** Model retries with path-relative file path errors — cannot resolve the output format.
- **caveman:** Explicitly not supported on LMS runtime (adapter-level, not model-specific).

## Better alternatives

No Liquid family model is recommended for coding tasks at this time. The edit format non-compliance makes this model unsuitable for any adapter evaluated in this benchmark. If Liquid family models are needed, a different model from the same family should be tested to confirm whether this is specific to lfm2-24b-a2b or systemic.

## Status

**drop** — all 12 adapters fail. The model does not conform to edit format on any adapter, making it unusable for agentic coding tasks. The only passing result (smoke-01-edit-file with aider) is partial: the model produces correct content but in the wrong format (markdown code blocks), and the adapter has to work around it. Smoke-00 (file creation) and smoke-02 (file editing) both fail consistently.

## Capability notes

**Critical-path weakness: edit format non-compliance.** The model outputs markdown code blocks (``` ... ```) instead of the structured edit format required by LMS adapters. This causes every adapter to fail — file creation fails (hello.txt never created), file editing fails (content written as separate garbage files), and search-replace fails (edit not applied, old content remains). The model *can* reason correctly (it identifies the missing Fibonacci number 5) but cannot express its output in the format adapters need.
