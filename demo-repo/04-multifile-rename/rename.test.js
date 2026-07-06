import { test } from 'node:test';
import assert from 'node:assert/strict';
import { celsiusToF } from './src/temperature.js';
import { describe } from './src/weather.js';
import * as temp from './src/temperature.js';

test('renamed function computes correctly', () => {
  assert.equal(celsiusToF(0), 32);
  assert.equal(celsiusToF(100), 212);
});

test('describe uses the renamed function and keeps its format', () => {
  assert.equal(describe(0), '0°C is 32°F');
  assert.equal(describe(100), '100°C is 212°F');
});

test('old name is no longer exported', () => {
  assert.equal(temp.toFahrenheit, undefined);
});
