#!/usr/bin/env node
// patch-jsonc-models.mjs <file.jsonc> <providerKey> <modelsJson> [<providerKey> <modelsJson> ...]
//
// Surgically replaces the "models": { ... } object inside named top-level
// provider blocks, leaving everything else in the file (comments, other
// providers, formatting) byte-for-byte untouched. Comment-aware: brace/quote
// matching skips over // and /* */ comments and string literals so it
// doesn't get confused by braces inside them.
//
// Rationale: opencode.jsonc is JSONC (has comments), so a naive
// parse-mutate-stringify round trip would silently drop every comment.
// This is intentionally dumb text surgery instead.

const [, , mode, file, ...rest] = process.argv;
if (!mode || !file || !["read", "write", "set", "get"].includes(mode)) {
  console.error("usage: patch-jsonc-models.mjs read  <file> <providerKey> [<providerKey> ...]");
  console.error("       patch-jsonc-models.mjs write <file> <providerKey> <modelsJson> [...]");
  console.error("       patch-jsonc-models.mjs set   <file> <dotted.path> <jsonScalar> [<path> <scalar> ...]");
  console.error("       patch-jsonc-models.mjs get   <file> <dotted.path>");
  process.exit(1);
}

const fs = await import("node:fs");
let text = fs.readFileSync(file, "utf8");

// Walk forward from `start`, tracking string/comment state, and return the
// index just past the closing brace matching the '{' found at or after start.
function findBlock(text, fromIdx) {
  let i = text.indexOf("{", fromIdx);
  if (i === -1) throw new Error("no opening brace found");
  const openIdx = i;
  let depth = 0;
  let inStr = false, strCh = "", inLineComment = false, inBlockComment = false, escape = false;
  for (; i < text.length; i++) {
    const c = text[i];
    const c2 = text[i + 1];
    if (inLineComment) {
      if (c === "\n") inLineComment = false;
      continue;
    }
    if (inBlockComment) {
      if (c === "*" && c2 === "/") { inBlockComment = false; i++; }
      continue;
    }
    if (inStr) {
      if (escape) { escape = false; continue; }
      if (c === "\\") { escape = true; continue; }
      if (c === strCh) inStr = false;
      continue;
    }
    if (c === "/" && c2 === "/") { inLineComment = true; i++; continue; }
    if (c === "/" && c2 === "*") { inBlockComment = true; i++; continue; }
    if (c === '"' || c === "'") { inStr = true; strCh = c; continue; }
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return { openIdx, closeIdx: i + 1 };
    }
  }
  throw new Error("unbalanced braces");
}

function indentOf(text, idx) {
  let start = text.lastIndexOf("\n", idx) + 1;
  const m = text.slice(start, idx).match(/^[ \t]*/);
  return m ? m[0] : "";
}

// Strip // and /* */ comments so a JSONC block can go through JSON.parse.
// String-aware, so a "//" inside a URL survives.
function stripComments(src) {
  let out = "", inStr = false, strCh = "", inLine = false, inBlock = false, escape = false;
  for (let i = 0; i < src.length; i++) {
    const c = src[i], c2 = src[i + 1];
    if (inLine) { if (c === "\n") { inLine = false; out += c; } continue; }
    if (inBlock) { if (c === "*" && c2 === "/") { inBlock = false; i++; } continue; }
    if (inStr) {
      out += c;
      if (escape) { escape = false; continue; }
      if (c === "\\") { escape = true; continue; }
      if (c === strCh) inStr = false;
      continue;
    }
    if (c === "/" && c2 === "/") { inLine = true; i++; continue; }
    if (c === "/" && c2 === "*") { inBlock = true; i++; continue; }
    if (c === '"' || c === "'") { inStr = true; strCh = c; out += c; continue; }
    out += c;
  }
  return out;
}

// Comment lines a human attached to each model entry, keyed by model id. These
// are load-bearing notes ("this quant is broken in oMLX"), so a resync that
// silently dropped them would destroy the reason a model is listed or excluded.
// Line-based and depth-aware: only comments directly above a depth-1 key count.
function harvestComments(blockText) {
  const byKey = {};
  let pending = [], depth = 0;
  for (const line of blockText.split("\n")) {
    const t = line.trim();
    if (t.startsWith("//")) { if (depth === 1) pending.push(t); continue; }
    const keyAtDepth1 = depth === 1 && /^"((?:[^"\\]|\\.)*)"\s*:/.exec(t);
    if (keyAtDepth1) {
      if (pending.length) byKey[JSON.parse(`"${keyAtDepth1[1]}"`)] = pending;
      pending = [];
    } else if (t && !t.startsWith("//")) {
      pending = [];
    }
    for (const ch of line) { if (ch === "{") depth++; else if (ch === "}") depth--; }
  }
  return byKey;
}

function renderModels(modelsObj, baseIndent, comments = {}) {
  const inner = baseIndent + "  ";
  const entries = Object.entries(modelsObj);
  if (entries.length === 0) return "{}";
  const chunks = entries.map(([id, val]) => {
    // Preserve the whole value object, not just .name — per-model overrides like
    // {"options": {"maxTokens": 32000}} are the user's tuning and rewriting them
    // to a bare name would silently reset it.
    const obj = val && typeof val === "object" ? val : { name: id };
    if (!obj.name) obj.name = id;
    const lead = (comments[id] || []).map((c) => `${inner}${c}\n`).join("");
    // Match the hand-written style already in these files: one line per model,
    // spaces inside the braces — so a resync produces a reviewable diff rather
    // than reformatting every untouched line.
    const props = Object.entries(obj).map(([k, v]) => `"${k}": ${JSON.stringify(v)}`);
    return lead + `${inner}${JSON.stringify(id)}: { ${props.join(", ")} }`;
  });
  return "{\n" + chunks.join(",\n") + "\n" + baseIndent + "}";
}

function locateModelsBlock(providerKey) {
  const providerNameRe = new RegExp(`"${providerKey}"\\s*:\\s*`, "g");
  let match, providerBlock = null;
  while ((match = providerNameRe.exec(text))) {
    // must be a top-level-ish key (preceded by newline/indent, not e.g. inside "models")
    const before = text.slice(0, match.index);
    const lineStart = before.lastIndexOf("\n") + 1;
    const linePrefix = text.slice(lineStart, match.index);
    if (/^[ \t]*$/.test(linePrefix)) {
      providerBlock = findBlock(text, match.index + match[0].length);
      break;
    }
  }
  if (!providerBlock) {
    console.error(`provider "${providerKey}" not found in ${file}`);
    process.exit(1);
  }
  const providerText = text.slice(providerBlock.openIdx, providerBlock.closeIdx);
  const modelsKeyRe = /"models"\s*:\s*/;
  const mm = modelsKeyRe.exec(providerText);
  if (!mm) {
    console.error(`provider "${providerKey}" has no "models" key`);
    process.exit(1);
  }
  const modelsFromIdx = providerBlock.openIdx + mm.index + mm[0].length;
  return findBlock(text, modelsFromIdx);
}

// Find `"key" :` within the (from, to) window and return the value-start index
// (just past the colon + whitespace) plus the key-match start. Comment/string
// aware via the same forward walk used by findBlock, so it never matches a key
// that appears inside a comment or string literal.
function locateKey(text, from, to, key) {
  const target = JSON.stringify(key); // quoted, escaped
  let i = from;
  let inStr = false, strCh = "", inLineComment = false, inBlockComment = false, escape = false;
  for (; i < to; i++) {
    const c = text[i];
    const c2 = text[i + 1];
    if (inLineComment) { if (c === "\n") inLineComment = false; continue; }
    if (inBlockComment) { if (c === "*" && c2 === "/") { inBlockComment = false; i++; } continue; }
    if (inStr) {
      if (escape) { escape = false; continue; }
      if (c === "\\") { escape = true; continue; }
      if (c === strCh) inStr = false;
      continue;
    }
    if (c === "/" && c2 === "/") { inLineComment = true; i++; continue; }
    if (c === "/" && c2 === "*") { inBlockComment = true; i++; continue; }
    if (c === '"' || c === "'") {
      // Does the quoted key start exactly here?
      if (text.startsWith(target, i)) {
        let j = i + target.length;
        while (j < to && /\s/.test(text[j])) j++;
        if (text[j] === ":") {
          j++;
          while (j < to && /\s/.test(text[j])) j++;
          return { keyStart: i, valueStart: j };
        }
      }
      inStr = true; strCh = c; continue;
    }
  }
  return null;
}

// Walk a dotted path (e.g. "provider.lmstudio.options.baseURL"). Returns the
// enclosing block of the final parent and the located leaf key (or null leaf if
// the final key is absent so callers can insert it). Throws on a missing
// intermediate object so we never silently corrupt the file.
function walkPath(path) {
  const segs = path.split(".");
  let block = { openIdx: 0, closeIdx: text.length }; // whole document
  for (let s = 0; s < segs.length - 1; s++) {
    const hit = locateKey(text, block.openIdx, block.closeIdx, segs[s]);
    if (!hit) throw new Error(`path segment "${segs[s]}" not found in ${file}`);
    block = findBlock(text, hit.valueStart);
  }
  const leafKey = segs[segs.length - 1];
  const leaf = locateKey(text, block.openIdx, block.closeIdx, leafKey);
  return { block, leafKey, leaf };
}

const SCALAR_RE = /^("(?:[^"\\]|\\.)*"|true|false|null|-?\d[\d.eE+-]*)/;

if (mode === "get") {
  const path = rest[0];
  const { leaf } = walkPath(path);
  if (!leaf) { console.error(`path "${path}" not found in ${file}`); process.exit(1); }
  const m = SCALAR_RE.exec(text.slice(leaf.valueStart));
  if (!m) { console.error(`value at "${path}" is not a scalar`); process.exit(1); }
  process.stdout.write(JSON.parse(m[1] === "null" ? "null" : m[1]) + "");
  process.exit(0);
}

if (mode === "set") {
  for (let k = 0; k < rest.length; k += 2) {
    const path = rest[k];
    const value = JSON.parse(rest[k + 1]); // caller passes a JSON scalar
    const { block, leafKey, leaf } = walkPath(path);
    const valJson = JSON.stringify(value);
    if (leaf) {
      const m = SCALAR_RE.exec(text.slice(leaf.valueStart));
      if (!m) throw new Error(`value at "${path}" is not a scalar (won't overwrite an object/array)`);
      text = text.slice(0, leaf.valueStart) + valJson + text.slice(leaf.valueStart + m[1].length);
    } else {
      // Insert leaf as the first entry of the parent block.
      const baseIndent = indentOf(text, block.openIdx);
      const inner = baseIndent + "  ";
      // Empty block "{ }" / "{}" → write single entry; else prepend with comma.
      const afterBrace = text.slice(block.openIdx + 1, block.closeIdx - 1);
      if (/^\s*$/.test(afterBrace)) {
        text = text.slice(0, block.openIdx) +
          `{\n${inner}${JSON.stringify(leafKey)}: ${valJson}\n${baseIndent}}` +
          text.slice(block.closeIdx);
      } else {
        text = text.slice(0, block.openIdx + 1) +
          `\n${inner}${JSON.stringify(leafKey)}: ${valJson},` +
          text.slice(block.openIdx + 1);
      }
    }
  }
  process.stdout.write(text);
  process.exit(0);
}

if (mode === "read") {
  const result = {};
  for (const providerKey of rest) {
    const { openIdx, closeIdx } = locateModelsBlock(providerKey);
    // Model blocks are JSONC in practice — users annotate why a model is listed
    // (or why a quant is excluded) — so comments must be stripped before parsing.
    result[providerKey] = JSON.parse(stripComments(text.slice(openIdx, closeIdx)));
  }
  process.stdout.write(JSON.stringify(result));
  process.exit(0);
}

// mode === "write"
for (let k = 0; k < rest.length; k += 2) {
  const providerKey = rest[k];
  const modelsObj = JSON.parse(rest[k + 1]);
  const { openIdx: mOpen, closeIdx: mClose } = locateModelsBlock(providerKey);
  const indent = indentOf(text, mOpen);
  const rendered = renderModels(modelsObj, indent, harvestComments(text.slice(mOpen, mClose)));
  text = text.slice(0, mOpen) + rendered + text.slice(mClose);
}

process.stdout.write(text);
