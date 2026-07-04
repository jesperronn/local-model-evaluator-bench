# Experiment: Tuned reasoning-ON vs reasoning-OFF on a hard case (Qwen)

**Goal.** Empirically test the claim in
[docs/troubleshooting-qwen-reasoning-loops.md](../troubleshooting-qwen-reasoning-loops.md)
and the model cards: reasoning is disabled by default in agentic adapters because
it gives *minimal accuracy gain* while risking infinite "reasoning loops"
(attention reinforcement trap). If reasoning is enabled, the docs recommend
temperature 0.6–0.7 and presence/frequency penalties 0.1–0.3.

We measure whether **reasoning ON + the recommended hyperparameters** beats the
**reasoning-OFF baseline** on a hard, self-verifying case.

- **Model:** `qwen/qwen3-coder-30b` (dense 30B, code-specialized MoE, 3B active).
- **Hard case:** `js-06-lint-and-test` (`difficulty: hard`, category `self-verify`
  — the agent must run tests + linter and iterate until both are green; graded by
  a pristine grader worth `tests + 1` points). This is exactly the "iterate on a
  contradiction" shape most likely to trigger a reasoning loop.
- **Adapter:** `cn` (Continue headless CLI) — the only LMS adapter whose config
  can *actually forward* per-request hyperparameters to the LM Studio API (via
  `defaultCompletionOptions`), and whose reasoning display is togglable
  (`--silent`).

## Plumbing caveat (important, discovered during setup)

The recommended hyperparameters in config.sh are **inert for the real adapters**:

- `config.sh` defines `ADAPTER_DEFAULT_TEMPERATURE=0.7` and `MAX_TOKENS`/`TOOL_CHOICE`
  only — there is **no** `ADAPTER_DEFAULT_PRESENCE_PENALTY` /
  `ADAPTER_DEFAULT_FREQUENCY_PENALTY` variable.
- None of the LMS adapters (`pi-lms.sh`, `cline-lms.sh`, `cn-lms.sh`) read
  `ADAPTER_DEFAULT_TEMPERATURE` or forward any temperature/penalty to the model.
  Those knobs only take effect if set server-side in the LM Studio model load
  config, or (for `cn`) via `defaultCompletionOptions` in its config.yaml.
- Reasoning on/off on **LMS** is *not* wired the way the doc table implies:
  `pi-lms.sh` has no `--thinking` flag (only `pi-mlx.sh` does);
  `cn-lms.sh` uses `--silent`, which strips `<think>` tags from *output* but does
  not stop the model from *generating* them. `caveman-lms.sh` is `exit 1`
  (unsupported).

Because of this, a faithful reasoning ON/OFF toggle on LMS is achieved here by a
**`/no_think` (off) vs `/think` (on)** system directive prepended to the prompt —
the mechanism qwen's chat template honors — combined with `cn`'s
`defaultCompletionOptions` for the tuned hyperparameters on the ON arm.

**Prep changes made (committed before the run):**

- `config.sh`: added `ADAPTER_DEFAULT_PRESENCE_PENALTY` and
  `ADAPTER_DEFAULT_FREQUENCY_PENALTY` (empty by default so baseline is
  unchanged), and `ADAPTER_REASONING` (`off`|`on`).
- `adapters/cn-lms.sh`: now appends `defaultCompletionOptions` (temperature
  always, penalties only when set) to the generated Continue config, and toggles
  `--silent` + `/no_think` vs `/think` on `ADAPTER_REASONING`. This makes the two
  arms drivable through the *real* adapter via env overrides. pi/cline were left
  untouched: pi has no CLI sampling flags and cline has none, so they cannot
  carry the tuned params.

## How to reproduce

```bash
# ARM A (baseline): reasoning off, no penalties (current default)
bin/bench --agent cn --model qwen/qwen3-coder-30b --cases js-06-lint-and-test \
  --difficulty hard

# ARM B (tuned): reasoning on + temp 0.65 / presence 0.15 / frequency 0.15
ADAPTER_REASONING=on \
ADAPTER_DEFAULT_TEMPERATURE=0.65 \
ADAPTER_DEFAULT_PRESENCE_PENALTY=0.15 \
ADAPTER_DEFAULT_FREQUENCY_PENALTY=0.15 \
  bin/bench --agent cn --model qwen/qwen3-coder-30b --cases js-06-lint-and-test \
  --difficulty hard
```

## Arms

| Arm | Reasoning | temperature | presence_penalty | frequency_penalty | Notes |
|-----|-----------|-------------|------------------|-------------------|-------|
| A (baseline) | OFF (`/no_think`, `--silent`) | model default | — | — | mirrors current agentic default |
| B (tuned)    | ON (`/think`, no `--silent`) | 0.65 | 0.15 | 0.15 | doc-recommended settings |

Both arms run through the real `adapters/cn-lms.sh` and the real `bin/bench`
grader (pristine `check/run.sh`), differing only by the env overrides shown
above — no forked adapter or reimplemented grading loop.

## Results

<!-- FILLED AFTER RUNS -->
_TBD — see table below once both arms complete._

| Arm | pass/total | score | latency (s) | status | loop signals (waits / think-tags) |
|-----|-----------|-------|-------------|--------|-----------------------------------|
| A (baseline, reasoning OFF) | – | – | – | – | – |
| B (tuned, reasoning ON)     | – | – | – | – | – |

**Δ (B − A):** accuracy _TBD_, latency _TBD_.

## Conclusion

_TBD._

## Recommendation

_TBD — do not change global `config.sh` `ADAPTER_DEFAULT_*` or model-card
defaults unless the data clearly shows tuned-reasoning-ON wins._
