# Task: Write a top-words CLI script

Implement `bin/topwords.sh` so that:

    bin/topwords.sh <file> <n>

prints the `<n>` most frequent words in `<file>`, one per line, formatted as:

    <count> <word>

Rules:
- Words are case-insensitive (lowercase them) and consist of letters only;
  split on any non-letter character.
- Sort by descending count. Break ties alphabetically (a before b).
- Print exactly `<n>` lines (or fewer if the file has fewer distinct words).
- The count and the word are separated by a single space.

Make the script executable and use a `#!/usr/bin/env bash` shebang.
