import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Store } from './src/store.js';
import { Cache } from './src/cache.js';

test('store.delete removes and reports existence', () => {
  const s = new Store();
  s.set('a', 1).set('b', 2);
  assert.equal(s.delete('a'), true);
  assert.equal(s.has('a'), false);
  assert.equal(s.delete('missing'), false);
  assert.equal(s.size, 1);
});

test('store.keys returns insertion order', () => {
  const s = new Store();
  s.set('x', 1).set('y', 2).set('z', 3);
  assert.deepEqual(s.keys(), ['x', 'y', 'z']);
});

test('cache stores and reads back', () => {
  const c = new Cache(2);
  c.set('a', 1).set('b', 2);
  assert.equal(c.get('a'), 1);
  assert.equal(c.get('b'), 2);
  assert.equal(c.size, 2);
});

test('cache evicts the oldest key when over capacity', () => {
  const c = new Cache(2);
  c.set('a', 1);
  c.set('b', 2);
  c.set('c', 3); // should evict 'a'
  assert.equal(c.get('a'), undefined);
  assert.equal(c.get('b'), 2);
  assert.equal(c.get('c'), 3);
  assert.equal(c.size, 2);
});

test('updating an existing key does not evict', () => {
  const c = new Cache(2);
  c.set('a', 1);
  c.set('b', 2);
  c.set('a', 99); // update in place
  assert.equal(c.size, 2);
  assert.equal(c.get('a'), 99);
  assert.equal(c.get('b'), 2);
});
