// A thin string-keyed store backed by a Map.
export class Store {
  constructor() {
    this._m = new Map();
  }
  set(key, value) {
    this._m.set(key, value);
    return this;
  }
  get(key) {
    return this._m.get(key);
  }
  has(key) {
    return this._m.has(key);
  }
  get size() {
    return this._m.size;
  }
  // TODO: add delete(key) -> boolean  and  keys() -> array of keys (insertion order)
}
