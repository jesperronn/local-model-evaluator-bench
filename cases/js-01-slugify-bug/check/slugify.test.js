import { test } from 'node:test';
import assert from 'node:assert/strict';
import { slugify } from './src/slugify.js';

test('basic', () => assert.equal(slugify('Hello World'), 'hello-world'));
test('trims and collapses', () => assert.equal(slugify('  Foo  Bar!! '), 'foo-bar'));
test('punctuation run -> single hyphen', () => assert.equal(slugify('a@@@b'), 'a-b'));
test('already sluggish', () => assert.equal(slugify('Already-A-Slug'), 'already-a-slug'));
