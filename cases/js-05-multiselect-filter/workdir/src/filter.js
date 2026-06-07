// Pure filtering logic for the item list UI (see index.html).
// Items look like: { name: string, type: 'A' | 'B' | 'C' }.

// Currently supports a SINGLE active type. The UI now needs multi-select —
// see task.md (add `filterByTypes`).
export function filterByType(items, type) {
  if (!type) return items.slice();
  return items.filter((item) => item.type === type);
}
