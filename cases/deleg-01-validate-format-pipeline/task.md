# Task: Build a validate → format → pipeline flow (spans three files)

Three files work together. Each has one unfinished function. Implement all three
and keep the existing `export` in each file.

`src/validate.js` — implement `validate(record)`. A record is `{ id, name, age }`.
Return `true` iff **all** hold, else `false` (never throw on bad input):
- `id` is a positive integer (`> 0`),
- `name` is a non-empty string,
- `age` is a number `>= 0`.

`src/format.js` — implement `format(record)`. Return the display string exactly:
`"#<id>: <name> (<age>)"`. Example: `{ id: 3, name: "Ada", age: 36 }` →
`"#3: Ada (36)"`.

`src/pipeline.js` — implement `process(records)`. Given an array of records,
return an array of formatted strings for **only the valid records, preserving
input order**. Use `validate()` to filter and `format()` to render; drop invalid
records. The imports are already wired.

No external dependencies.
