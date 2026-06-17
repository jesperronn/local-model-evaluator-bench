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
    // Check if key already exists
    if (this.store.has(key)) {
      this.store.set(key, value);
      return this;
    }
    
    // If at capacity, evict the oldest entry
    if (this.store.size >= this.capacity) {
      // Get the first key (oldest) and remove it
      const keys = Array.from(this.store._m.keys());
      const oldestKey = keys[0];
      this.store._m.delete(oldestKey);
    }
    
    // Add the new key-value pair
    this.store.set(key, value);
    return this;
  }
  get size() {
    return this.store.size;
  }
}
