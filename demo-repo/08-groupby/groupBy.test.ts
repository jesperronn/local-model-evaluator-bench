import { test } from 'node:test';
import assert from 'node:assert/strict';
import { groupBy } from './src/groupBy.ts';

test('groups by parity, preserving order', () => {
  const out = groupBy([1, 2, 3, 4], (n) => (n % 2 === 0 ? 'even' : 'odd'));
  assert.deepEqual(out, { odd: [1, 3], even: [2, 4] });
});

test('groups objects by a numeric key', () => {
  const data = [
    { id: 1, age: 30 },
    { id: 2, age: 30 },
    { id: 3, age: 40 },
  ];
  const out = groupBy(data, (d) => d.age);
  assert.deepEqual(out[30].map((d) => d.id), [1, 2]);
  assert.deepEqual(out[40].map((d) => d.id), [3]);
});

test('empty input -> empty object', () => {
  assert.deepEqual(groupBy([], (x) => String(x)), {});
});
