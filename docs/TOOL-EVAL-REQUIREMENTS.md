# Tool evaluation page — requirements

Related: [MODEL-EVAL-REQUIREMENTS.md](MODEL-EVAL-REQUIREMENTS.md) · [../adapters/](../adapters/) · [../BENCHMARK-RESULTS.md](../BENCHMARK-RESULTS.md)

Each adapter in `adapters/` gets one evaluation page at
`docs/tools/<name>.md`, where `<name>` matches the adapter filename without
extension (e.g. `aider.md`, `opencode.md`).

A tool eval page documents *how the tool behaves* as a coding agent: its edit
mechanism, its iteration capability, its failure modes, and tuning decisions
made in the adapter script. This is distinct from per-model results — the
same tool can behave very differently across models, and those patterns belong
here.

---

## Required sections

### Metadata
- **Tool name** and **CLI command** (e.g. `aider`, `opencode run`, `codex exec`)
- **Version** — output of `<cli> --version` at time of last bench run
- **Adapter script** — link to `adapters/<name>.sh`
- **How it connects to LM Studio** — provider mechanism (openai-compat,
  native lmstudio provider, custom model_provider config, etc.)
- **Last reviewed** — date

### Edit mechanism
How the tool actually modifies files in the sandbox:

- **Format** — does it produce a diff/patch, a whole-file rewrite, a search-
  and-replace block, or something else? Which format does the model need to emit?
- **File targeting** — does it need files named explicitly (e.g. aider's chat
  files), does it discover them from the prompt, or does it operate on the whole
  CWD?
- **Multi-file edits** — can it edit more than one file in a single turn?
  Does it do so reliably?

### Iteration / self-verify behaviour
For `self-verify` cases (js-05, js-06) the task prompt tells the agent to run
the provided test/lint suite and iterate until green. Document:

- Does the tool actually run the tests between edits?
- How many rounds does it typically take to reach green?
- Does it give up early, loop endlessly, or exit cleanly?
- Any models where the loop works better or worse

### Failure modes
Patterns observed across multiple models and runs:

**Format failures** — the model's output doesn't match the edit format the
tool expects (malformed diff, wrong block syntax, missing delimiters). Note
whether this is recoverable (tool retries) or terminal (edit not applied).

**No-edit failures** — the tool runs, the model responds, but the file is
unchanged. Common with aider when no file is passed in the chat.

**Lingering / timeout** — the tool completes the edit but doesn't exit,
running until the harness kills it. Distinguish from a genuine timeout
(edit not done). Note which models and cases trigger this most.

**Crash / non-zero exit** — the CLI itself errors out. Note the exit code,
the condition, and whether the edit was applied before the crash.

**Context / truncation** — the prompt or file content exceeds the model's
context; the tool may silently truncate or hallucinate. Note any observable
symptoms.

### Adapter flags and their rationale
Document every non-default flag used in the adapter script and why. This
makes future tuning legible. Example:

| Flag | Reason |
|------|--------|
| `--yes-always` | suppress interactive approval prompts |
| `--no-auto-commits` | sandbox has no git; commits would error |
| `--no-check-update` | avoid network call on every run |

### Better alternatives
When is this tool *not* the right choice? Name specific alternatives and the conditions under which they win:

- Which other adapters consistently outscore this one, and on what case types?
- When should you reach for a different tool instead?
- If this tool has a niche where it clearly leads, name it here too.

Keep it concrete — a sentence per alternative is enough. This section makes the eval page actionable for someone choosing between tools.

### Known issues
Concrete, reproducible problems with the tool itself (not model-specific):

- Bugs or missing features in the CLI version under test
- Setup requirements that must be met outside the adapter script
- Cases where the harness contract (stdin prompt, CWD sandbox) is imperfectly
  supported by this tool

### Status
One of: **stable** · **needs-tuning** · **broken** · **under-evaluation** ·
**retired**

| Status | Meaning |
|--------|---------|
| stable | Works reliably across most models; no known blockers |
| needs-tuning | Functional but leaving points on the table — a flag change or prompt tweak would likely improve scores |
| broken | Consistently fails to apply edits or crashes; not currently contributing useful benchmark data |
| under-evaluation | Newly added; not enough data yet |
| retired | Removed from `adapters/`; page kept for historical reference |

Include a one-line rationale and, for **needs-tuning** / **broken**, a
suggested fix.

---

## Optional sections

### Per-model interaction notes
Some models interact with a tool's edit format in specific ways (e.g. a
model that only produces whole-file rewrites when aider expects a diff).
Keep these brief and cross-reference the relevant model eval page.

### Observations across versions
If the tool CLI has been upgraded between bench runs, note what changed and
whether it affected scores.

### Comparison with other adapters
For the same model and case, how does this tool compare to the others? When
is it the best choice? When is it the worst?

### Configuration outside the adapter script
Some tools require global config (e.g. `~/.config/opencode/opencode.json`,
`~/.codex/config.toml`). Link to `docs/SETUP.md` for the setup steps, and
note here what the adapter script assumes is already in place.

---

## Writing style

- Write about *tool behaviour*, not scores. A sentence like "aider leaves the
  file unedited when no file is passed in the chat" is useful; "aider scores
  2/4 on js-01" belongs in `BENCHMARK-RESULTS.md`.
- Name the case and adapter when citing a specific observation.
- Flag whether something is model-agnostic (tool issue) or model-dependent
  (interaction).
- Update **Last reviewed** and **Status** after each bench run that includes
  this adapter.
- Keep sections short; use a table when there are ≥3 comparable items.
