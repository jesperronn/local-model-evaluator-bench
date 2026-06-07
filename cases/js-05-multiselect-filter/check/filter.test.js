import { test } from 'node:test';
import assert from 'node:assert/strict';
import { filterByTypes } from './src/filter.js';

const items = [
  { name: 'apple', type: 'A' },
  { name: 'banana', type: 'B' },
  { name: 'cherry', type: 'C' },
  { name: 'avocado', type: 'A' },
];
const names = (arr) => arr.map((i) => i.name);

test('empty / null selection shows all', () => {
  assert.deepEqual(names(filterByTypes(items, [])), ['apple', 'banana', 'cherry', 'avocado']);
  assert.deepEqual(names(filterByTypes(items, null)), ['apple', 'banana', 'cherry', 'avocado']);
});

test('single selected type', () => {
  assert.deepEqual(names(filterByTypes(items, ['A'])), ['apple', 'avocado']);
});

test('multiple types — original list order preserved', () => {
  assert.deepEqual(names(filterByTypes(items, ['B', 'A'])), ['apple', 'banana', 'avocado']);
});

test('no matches returns empty', () => {
  assert.deepEqual(filterByTypes(items, ['Z']), []);
});

test('does not mutate input', () => {
  const copy = items.slice();
  filterByTypes(items, ['A']);
  assert.deepEqual(items, copy);
});
