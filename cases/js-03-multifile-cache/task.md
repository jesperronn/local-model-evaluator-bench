# Task: Finish the capacity cache (spans two files)

This involves **two files** that work together.

`src/store.js` defines a `Store` (a thin Map wrapper). It is missing two methods:

- `delete(key)` — remove the key; return `true` if it existed, else `false`.
- `keys()` — return an array of the keys in **insertion order**.

`src/cache.js` defines a fixed-capacity `Cache` backed by a `Store`. Its `set`
method is unfinished. Make `set(key, value)` behave as a capacity-bounded cache:

- If `key` is new and the cache is **at capacity**, first evict the **oldest**
  key (the one inserted earliest), then insert the new key.
- If `key` already exists, update its value **without** evicting anything.
- Return `this`.

You must edit **both** files: implement `delete`/`keys` in `store.js` and use
them from `cache.js`. Keep the existing exports (`Store`, `Cache`). No external
dependencies.
