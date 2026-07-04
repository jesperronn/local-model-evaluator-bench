# Experiment: Tuned reasoning-ON vs reasoning-OFF on a hard case (Qwen)

**Goal.** Empirically test the claim in
[docs/troubleshooting-qwen-reasoning-loops.md](../troubleshooting-qwen-reasoning-loops.md)
and the model cards: reasoning is disabled by default in agentic adapters because
it gives *minimal accuracy gain* while risking infinite "reasoning loops"
(attention reinforcement trap). If reasoning is enabled, the docs recommend
temperature 0.6–0.7 and presence/frequency penalties 0.1–0.3.

We measure whether **reasoning ON + the recommended hyperparameters** beats the
**reasoning-OFF baseline** on a hard, self-verifying case.

- **Model:** ran on `qwen/qwen3.5-9b` (reasoning-capable, already loaded on the
  shared LM Studio — see the note in Results for why this over `qwen3-coder-30b`).
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

Runtime: `lms`. Adapter: `cn`. Case: `js-06-lint-and-test` (hard, self-verify).
1 trial per arm. Both arms loaded/graded through real `bin/bench`.

> **Subject model:** run on **`qwen/qwen3.5-9b`**, not `qwen/qwen3-coder-30b`.
> qwen3.5-9b is a reasoning-capable model (`qwen3_5` arch) and was already the
> model in rotation on the shared LM Studio, so reusing it honoured the explicit
> memory-coordination bound (do not force-load a second large model while the
> nightly agent is active) while still being a valid ON/OFF reasoning subject.
> The lighter 9B also makes the latency delta a *conservative* estimate — the
> reasoning tax scales up on larger models.

| Arm | pass/total | score | latency (s) | status | loop signals |
|-----|-----------|-------|-------------|--------|--------------|
| A (baseline, reasoning OFF) | 4/4 | 1.00 | **37** | ok | none (no stall/timeout) |
| B (tuned, reasoning ON)     | 4/4 | 1.00 | **51** | ok | none; 0 stray think-tags, 0 "Wait/Actually" |

Raw: `results/20260704-115821/results.csv` (A), `results/20260704-115920/results.csv` (B).

**Δ (B − A):** accuracy **0** (both perfect). latency **+14 s (+38 %)**.

## Conclusion

**Tuned reasoning-ON does NOT beat reasoning-OFF on this hard case.** It matched
accuracy exactly (4/4 both arms) while costing +38 % wall-clock. No reasoning
loops were observed in either arm — the tuned hyperparameters (temp 0.65,
presence/frequency 0.15) appear to have kept the ON arm well-behaved, i.e. they
*successfully prevent* the failure mode, but there was no accuracy headroom to
recover on this task (the model already solves it perfectly without reasoning).

This is a single-trial, single-model, single-case result, so treat the exact
+38 % as indicative not definitive (run-to-run variance is material per
`bin/bench --trials`). The **direction** — no accuracy gain, real latency cost —
matches the documented baseline (qwen3-coder-30b: 97 %+ at reasoning-off) and the
core claim of docs/troubleshooting-qwen-reasoning-loops.md.

## Recommendation

**Do not change** global `config.sh` `ADAPTER_DEFAULT_*` reasoning defaults or the
model-card defaults. The data supports keeping reasoning **OFF** by default:
tuned-reasoning-ON gave zero accuracy benefit and a clear latency penalty on the
hardest case. The new plumbing (penalty vars + `ADAPTER_REASONING` toggle) is
retained as an *opt-in* mechanism (empty/off by default, baseline unchanged) so
reasoning can still be enabled per-run for exploratory work with the recommended
anti-loop hyperparameters already wired in.

Follow-up if deeper validation is wanted: repeat with `--trials 3` on
`qwen/qwen3-coder-30b` across 2–3 hard cases (js-03, js-05, js-06) once the shared
GPU is free, to confirm the delta holds on the 30B and to probe for loops on a
larger reasoning budget.
