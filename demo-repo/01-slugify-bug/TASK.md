# Task: Fix the slugify bug

The function in `src/slugify.js` is supposed to turn an arbitrary string into a
clean URL slug, but it has bugs. A correct slug must:

1. Be lowercase.
2. Replace every run of non-alphanumeric characters with a single hyphen.
3. Have no leading or trailing hyphens.

Examples:
- `"Hello World"`        -> `"hello-world"`
- `"  Foo  Bar!! "`      -> `"foo-bar"`
- `"a@@@b"`              -> `"a-b"`
- `"Already-A-Slug"`     -> `"already-a-slug"`

Edit `src/slugify.js` so it behaves correctly. Keep the named export
`slugify`. Do not rename the file or the function.
