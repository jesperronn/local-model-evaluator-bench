import { test } from 'node:test';
import assert from 'node:assert/strict';
import { total } from './src/total.js';

test('sums a list', () => assert.equal(total([1, 2, 3]), 6));
test('empty list is zero', () => assert.equal(total([]), 0));
test('handles negatives', () => assert.equal(total([-1, 1, -2]), -2));
