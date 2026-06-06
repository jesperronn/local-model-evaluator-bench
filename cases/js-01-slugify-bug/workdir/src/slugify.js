// Turn an arbitrary string into a URL slug.
// BUG: this only lowercases and swaps spaces — it leaves punctuation in place
// and can emit leading/trailing or doubled hyphens.
export function slugify(input) {
  return input.toLowerCase().replace(/ /g, '-');
}
