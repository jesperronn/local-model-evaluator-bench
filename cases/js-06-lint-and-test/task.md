# Task: Make both the tests and the linter pass

`src/total.js` is supposed to sum the numbers in an array, but it has a **bug**
*and* **style problems** (it violates the project's `.editorconfig`: it uses a
tab for indentation and has trailing whitespace).

Two checks must pass:

```
npm test     # the function must be correct
npm run lint # the code must satisfy .editorconfig (spaces not tabs, no
             # trailing whitespace, file ends with a newline)
```

Fix `src/total.js` so that **both** commands exit cleanly. Run them, see what
fails, fix, and **re-run until both are green**. Keep the named export `total`.
