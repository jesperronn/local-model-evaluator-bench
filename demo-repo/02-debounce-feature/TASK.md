# Task: Implement `debounce`

`src/debounce.js` exports a stub `debounce`. Implement it so that:

1. `debounce(fn, wait)` returns a new function.
2. Calling the returned function delays invoking `fn` until `wait` ms have
   passed since the **last** call. Rapid calls reset the timer.
3. `fn` is called with the arguments of the **most recent** call, and with the
   same `this`.
4. The returned function has a `.cancel()` method that cancels any pending
   invocation.

Use the named export `debounce`. Do not add external dependencies.
