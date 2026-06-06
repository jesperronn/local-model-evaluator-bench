# Task: Implement a typed `groupBy`

Implement `groupBy` in `src/groupBy.ts`:

```ts
export function groupBy<T, K extends string | number>(
  items: T[],
  keyOf: (item: T) => K,
): Record<K, T[]>
```

It groups `items` into an object keyed by `keyOf(item)`. Order of items within
each group must match their order in the input. Keep the exact signature and
the named export `groupBy`. No external dependencies.

Example:
```ts
groupBy([1, 2, 3, 4], (n) => (n % 2 === 0 ? 'even' : 'odd'))
// => { odd: [1, 3], even: [2, 4] }
```
