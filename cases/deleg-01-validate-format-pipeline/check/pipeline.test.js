import test from "node:test";
import assert from "node:assert/strict";
import { validate } from "./src/validate.js";
import { format } from "./src/format.js";
import { process } from "./src/pipeline.js";

test("validate accepts a well-formed record", () => {
  assert.equal(validate({ id: 1, name: "Ada", age: 36 }), true);
});
test("validate rejects a non-positive id", () => {
  assert.equal(validate({ id: 0, name: "Ada", age: 36 }), false);
});
test("validate rejects an empty name", () => {
  assert.equal(validate({ id: 1, name: "", age: 36 }), false);
});
test("validate rejects a negative age", () => {
  assert.equal(validate({ id: 1, name: "Ada", age: -1 }), false);
});
test("format renders the canonical string", () => {
  assert.equal(format({ id: 3, name: "Ada", age: 36 }), "#3: Ada (36)");
});
test("pipeline filters invalid records then formats in order", () => {
  const input = [
    { id: 1, name: "Ada", age: 36 },
    { id: 0, name: "Bad", age: 5 },
    { id: 2, name: "Bo", age: 0 },
    { id: 3, name: "", age: 9 },
  ];
  assert.deepEqual(process(input), ["#1: Ada (36)", "#2: Bo (0)"]);
});
