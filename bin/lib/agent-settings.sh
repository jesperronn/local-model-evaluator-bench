#!/usr/bin/env bash
# bin/lib/agent-settings.sh — helpers for writing global settings (endpoint,
# api key, default model) into each coding agent's NATIVE config file.
#
# Sourced by bin/agents-config. Kept OUT of lib/common.sh (which every adapter
# sources) because these are config-mutation helpers, not general runtime utils.
#
# Design goals: idempotent (re-run = no-op), non-clobbering (only the targeted
# keys change), air-gapped (only jq / node / awk / sed — no yq/pyyaml).
#
# Requires: $C_* colors + ok()/warn()/err() from lib/common.sh (already sourced
# by the caller). Falls back to plain echo if those are absent.

_AS_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_AS_MJS="$_AS_HERE/bin/lib/patch-jsonc-models.mjs"

# ── commit_if_changed <target> <label> <WRITE> ───────────────────────────────
# Reads the intended file content from stdin. Diffs against <target>; on any
# difference prints a unified diff and, when WRITE=1, backs up (timestamped) and
# overwrites. When the target does not exist it is created (WRITE=1) or shown as
# a full-file addition (dry-run). This is the single idempotency path shared by
# the model-list sync and every settings writer.
commit_if_changed() {
  local target="$1" label="$2" write="$3"
  local tmp; tmp="$(mktemp)"
  cat > "$tmp"

  if [ ! -f "$target" ]; then
    echo "── $label (new) ──"
    diff -u /dev/null "$tmp" || true
    if [ "$write" = "1" ]; then
      mkdir -p "$(dirname "$target")"
      mv "$tmp" "$target"
      echo "created $target"
    else
      rm -f "$tmp"
    fi
    return 0
  fi

  if ! diff -q "$target" "$tmp" >/dev/null 2>&1; then
    echo "── $label ──"
    diff -u "$target" "$tmp" || true
    if [ "$write" = "1" ]; then
      cp "$target" "$target.bak.$(date +%Y%m%d%H%M%S 2>/dev/null || echo backup)"
      mv "$tmp" "$target"
      echo "wrote $target"
    else
      rm -f "$tmp"
    fi
  else
    echo "$label: up to date"
    rm -f "$tmp"
  fi
}

# ── YAML: flat top-level key upsert (aider) ──────────────────────────────────
# stdin config → stdout. Replaces the `key:` line if present, else appends it.
yaml_upsert_flat() {
  local key="$1" value="$2"
  awk -v k="$key" -v v="$value" '
    { if ($0 ~ "^"k":") { print k": "v; done=1 } else print }
    END { if (!done) print k": "v }
  '
}

# stdin config → stdout value (empty if absent). Reader for --verify.
yaml_get_flat() {
  local key="$1"
  awk -v k="$key" '$0 ~ "^"k":" { sub("^"k":[ \t]*", ""); print; exit }'
}

# ── YAML: nested parent→child→leaf value replace, REPLACE-ONLY (hermes) ───────
# stdin config → stdout. Only rewrites `<leaf>:` lines that live inside the
# parent→child block, matched at exact indentation. Never inserts a missing key
# (hermes owns/re-serializes its file; inserting risks duplicate keys). Whether
# the key was found is reported on fd 3 if open, else inferred by the caller via
# yaml_get_nested.
yaml_set_nested() {
  local parent="$1" child="$2" leaf="$3" value="$4" unit="${5:-    }"
  awk -v parent="$parent" -v child="$child" -v leaf="$leaf" -v val="$value" \
      -v i1="$unit" -v i2="$unit$unit" '
    function ind(s){ match(s, /^ */); return RLENGTH }
    {
      line=$0
      if (line ~ "^"parent":[ \t]*$") { inpar=1; inchild=0; print; next }
      if (inpar) {
        if (line ~ /^[^ ]/) { inpar=0; inchild=0; print; next }   # dedent to col 0
        if (ind(line)==length(i1) && line ~ "^"i1 child":[ \t]*$") { inchild=1; print; next }
        if (inchild) {
          if (line !~ /^[ ]*$/ && ind(line) <= length(i1)) { inchild=0 }  # left child block
          else if (line ~ "^"i2 leaf":") { print i2 leaf": "val; next }
        }
      }
      print
    }
  '
}

# stdin config → stdout value (empty if absent). Reader for --verify.
yaml_get_nested() {
  local parent="$1" child="$2" leaf="$3" unit="${4:-    }"
  awk -v parent="$parent" -v child="$child" -v leaf="$leaf" \
      -v i1="$unit" -v i2="$unit$unit" '
    function ind(s){ match(s, /^ */); return RLENGTH }
    {
      line=$0
      if (line ~ "^"parent":[ \t]*$") { inpar=1; inchild=0; next }
      if (inpar) {
        if (line ~ /^[^ ]/) { inpar=0; inchild=0; next }
        if (ind(line)==length(i1) && line ~ "^"i1 child":[ \t]*$") { inchild=1; next }
        if (inchild) {
          if (line !~ /^[ ]*$/ && ind(line) <= length(i1)) { inchild=0 }
          else if (line ~ "^"i2 leaf":") { sub("^"i2 leaf":[ \t]*",""); print; exit }
        }
      }
    }
  '
}

# Quote a shell string as a JSON scalar (for jsonc_set values).
json_str() { jq -nc --arg v "$1" '$v'; }

# ── JSON (pi): jq wrapper → stdout ───────────────────────────────────────────
# json_set <file> <jq-program> [jq-args...]   e.g. json_set f '.a=$x' --arg x v
json_set() {
  local file="$1" prog="$2"; shift 2
  jq "$@" "$prog" "$file"
}

# ── JSONC (opencode): comment-safe path set/get via the mjs patcher ───────────
# jsonc_set <file> <dotted.path> <jsonScalar> [<path> <scalar> ...]
jsonc_set() {
  local file="$1"; shift
  node "$_AS_MJS" set "$file" "$@"
}
# jsonc_get <file> <dotted.path> → value on stdout (nonzero exit if absent)
jsonc_get() {
  node "$_AS_MJS" get "$1" "$2"
}
