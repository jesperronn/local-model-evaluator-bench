# Task: Make the list filter multi-select (run the tests, iterate until green)

`index.html` shows a list of items, each with a `type` of `A`, `B`, or `C`, and
controls to filter them. Today the filtering logic in `src/filter.js` only
supports **one** active type at a time. We want **multi-select**: the user can
enable any combination of A/B/C and see items of *any* selected type.

Add a function to `src/filter.js`:

```js
export function filterByTypes(items, types)
```

- `types` is an array of type strings (e.g. `['A', 'C']`), or a Set.
- Return the items whose `type` is in `types`, **preserving the original list
  order** (not the selection order).
- If `types` is empty, `null`, or `undefined`, return **all** items.
- Keep it a pure function (don't mutate `items`). Keep the export named
  `filterByTypes`.

Also update the controls in `index.html` to checkboxes (A/B/C) wired to
`filterByTypes` so multiple can be active at once.

**This task is self-verifying.** A test file is included. Run:

```
npm test
```

and keep fixing `src/filter.js` until **all tests pass**.
