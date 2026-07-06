import { test } from 'node:test';
import assert from 'node:assert/strict';
import { debounce } from './src/debounce.js';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

test('invokes once after the wait', async () => {
  let calls = 0;
  const d = debounce(() => calls++, 30);
  d(); d(); d();
  assert.equal(calls, 0);
  await sleep(60);
  assert.equal(calls, 1);
});

test('uses args of the most recent call', async () => {
  let seen;
  const d = debounce((x) => (seen = x), 20);
  d(1); d(2); d(3);
  await sleep(50);
  assert.equal(seen, 3);
});

test('cancel prevents invocation', async () => {
  let calls = 0;
  const d = debounce(() => calls++, 20);
  d();
  d.cancel();
  await sleep(50);
  assert.equal(calls, 0);
});

test('preserves this', async () => {
  const obj = { v: 7, run: null };
  obj.run = debounce(function () { obj.captured = this.v; }, 20);
  obj.run();
  await sleep(50);
  assert.equal(obj.captured, 7);
});
