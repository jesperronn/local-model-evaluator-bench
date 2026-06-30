#!/usr/bin/env bash
# bin/lint-cards.test.sh — verify bin/lint-cards against fixture cards.
# Lints throwaway cards (in a tmpdir) via --card against the real CARD-SPEC.
# Run directly: bin/lint-cards.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$HERE/bin/lint-cards"

C_GRN=$'\033[32m'; C_RED=$'\033[31m'; C_RST=$'\033[0m'
pass=0; fail=0
check() {  # desc  expected  actual
  if [ "$2" = "$3" ]; then printf '%s %s\n' "${C_GRN}[PASS]${C_RST}" "$1"; pass=$((pass+1))
  else printf '%s %s\n  expected: %q\n  actual:   %q\n' "${C_RED}[FAIL]${C_RST}" "$1" "$2" "$3"; fail=$((fail+1)); fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/models" "$TMP/tools"

# --- a fully-conforming model card -------------------------------------------
cat > "$TMP/models/good.md" <<'EOF'
# good/model

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 100% across working adapters |
| **Speed (avg)** | ~48s per case |
| **Best adapter** | codex |
| **Recommended for** | multi-file edits |
| **Status** | keep |

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | good/model |
| **Quantization** | MLX 6-bit |
| **Disk size** | 22 GB |
| **Context window** | 65536 |

## Results summary
all pass.

## Timing observations
fastest codex ~19s.

## Failure patterns
none.

## Better alternatives
none — best in class.

## Status
keep — top scorer.
EOF

# --- a broken model card: missing Quick verdict + has a TODO -----------------
cat > "$TMP/models/bad.md" <<'EOF'
# bad/model

## Metadata

| Field | Value |
|-------|-------|
| **Disk size** | <!-- TODO --> |

## Status
watch.
EOF

# --- a model card with an empty Quick verdict metric -------------------------
cat > "$TMP/models/empty-metric.md" <<'EOF'
# em/model

## Quick verdict

| Metric | Value |
|--------|-------|
| **Accuracy** | 90% |
| **Speed (avg)** |  |
| **Best adapter** | codex |
| **Recommended for** | edits |
| **Status** | keep |

## Metadata
| Field | Value |
| **Model key** | em/model |

## Results summary
x.
## Timing observations
x.
## Failure patterns
none.
## Better alternatives
none.
## Status
keep.
EOF

run_json() { "$LINT" --card "$1" --type "$2" --json 2>/dev/null; }

ok_good="$(run_json "$TMP/models/good.md" model | grep -o '"ok":true')"
check "fully-conforming model card passes" '"ok":true' "$ok_good"

bad_qv="$(run_json "$TMP/models/bad.md" model | grep -c 'missing required section: ## Quick verdict')"
check "missing Quick verdict is flagged" "1" "$bad_qv"

bad_todo="$(run_json "$TMP/models/bad.md" model | grep -c 'placeholder')"
check "TODO placeholder is flagged" "1" "$bad_todo"

empty_metric="$(run_json "$TMP/models/empty-metric.md" model | grep -c 'Quick verdict missing/empty metric: Speed')"
check "empty Quick verdict metric is flagged" "1" "$empty_metric"

# --- exit codes --------------------------------------------------------------
"$LINT" --card "$TMP/models/good.md" --type model >/dev/null 2>&1
check "exit 0 when card passes" "0" "$?"
"$LINT" --card "$TMP/models/bad.md" --type model >/dev/null 2>&1
check "exit 1 when card fails" "1" "$?"

# --- type inference from path ------------------------------------------------
mkdir -p "$TMP/runtimes"
infer="$("$LINT" --card "$TMP/models/good.md" --json 2>/dev/null | grep -o '"ok":true')"
check "type inferred from /models/ path" '"ok":true' "$infer"

echo
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
