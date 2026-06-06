// Implement a typed groupBy. See task.md.
export function groupBy<T, K extends string | number>(
  items: T[],
  keyOf: (item: T) => K,
): Record<K, T[]> {
  // TODO: implement
  throw new Error('not implemented');
}
