# Doc templates

> **Canonical spec moved.** The required/optional sections and copy-paste
> skeletons now live in **[../CARD-SPEC.md](../CARD-SPEC.md)** — the single source
> of truth. The individual `*-card-template.md` files in this folder are
> redirect stubs. The design principles below remain valid background.

Three card formats — one each for **models**, **tools/agents**, and **runtimes**.
All three share the same structural principles.

> These cards are **data-collection intermediates** — they record what was measured, when, and under what conditions. The end output is the leaderboard and survey-style recommendations that answer "what should I use?". See [docs/PURPOSE.md](../PURPOSE.md) for how cards, leaderboard, and surveys relate.

## Templates

| Template | Use for |
|----------|---------|
| [model-card-template.md](model-card-template.md) | Every file under `docs/models/` |
| [tool-card-template.md](tool-card-template.md) | Every file under `docs/tools/` and `docs/extensions/` |
| [runtime-card-template.md](runtime-card-template.md) | Every file under `docs/runtimes/` (planned) |

---

## Design principles

### 1. Accuracy and speed are co-equal

Every card leads with a **Quick verdict** table that shows **Accuracy** and **Speed (avg)** in equal positions — neither is a footnote of the other.

The standing rule: **when two items have equal accuracy, the faster one wins.** This rule is stated on every card to keep the priority visible.

Speed must always be filled with a measured value. "Unknown" is only acceptable before any runs have been performed.

### 2. Progressive disclosure

Cards are ordered from least to most detail:

1. **Quick verdict** — 5 fields, fits on a screen; answers "should I use this?"
2. **Metadata** — static facts (size, version, formats)
3. **Results summary** — aggregate accuracy + speed per adapter/model
4. **Per-case breakdown / timing observations** — only when the detail adds insight
5. **Failure patterns / known issues** — only document repeatable failures
6. **Observations across runs** — append-only log; newest first

A reader who only wants the headline reads the quick verdict. A reader debugging a failure reads all the way down.

### 3. Consistency across card types

All three templates use the same section order and naming so you can mentally diff them:
`Quick verdict → Metadata → Results → Timing → Failures → Observations → Status`

The content differs, but the skeleton is identical.

### 4. Measured vs inferred

Every results table must say where the numbers come from. If a value is inferred from a similar adapter rather than directly measured, mark it `(inferred)`. If it is not yet measured, leave the cell blank and add a comment — don't guess.

---

## Existing example

[best-current-airgapped-local-models-example-2026-06.md](best-current-airgapped-local-models-example-2026-06.md) — a research-style comparison document (not a card). It follows different conventions (broad survey, not per-item card).
