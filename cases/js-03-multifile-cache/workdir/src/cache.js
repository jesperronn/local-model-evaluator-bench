import { Store } from './store.js';

// A fixed-capacity cache backed by a Store. See task.md.
export class Cache {
  constructor(capacity) {
    this.capacity = capacity;
    this.store = new Store();
  }
  get(key) {
    return this.store.get(key);
  }
  set(key, value) {
    // TODO: enforce the capacity bound (evict oldest on a new key when full),
    // update-in-place for existing keys, and return this.
    throw new Error('not implemented');
  }
  get size() {
    return this.store.size;
  }
}
