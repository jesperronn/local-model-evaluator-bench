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
if (!mode || !file || (mode !== "read" && mode !== "write")) {
  console.error("usage: patch-jsonc-models.mjs read <file> <providerKey> [<providerKey> ...]");
  console.error("       patch-jsonc-models.mjs write <file> <providerKey> <modelsJson> [...]");
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

function renderModels(modelsObj, baseIndent) {
  const inner = baseIndent + "  ";
  const entries = Object.entries(modelsObj);
  if (entries.length === 0) return "{}";
  const lines = entries.map(([id, val]) => {
    const name = val && val.name ? val.name : id;
    return `${inner}${JSON.stringify(id)}: { "name": ${JSON.stringify(name)} }`;
  });
  return "{\n" + lines.join(",\n") + "\n" + baseIndent + "}";
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

if (mode === "read") {
  const result = {};
  for (const providerKey of rest) {
    const { openIdx, closeIdx } = locateModelsBlock(providerKey);
    // Strip comments naively (none expected inside model entries) then parse.
    result[providerKey] = JSON.parse(text.slice(openIdx, closeIdx));
  }
  process.stdout.write(JSON.stringify(result));
  process.exit(0);
}

for (let k = 0; k < rest.length; k += 2) {
  const providerKey = rest[k];
  const modelsObj = JSON.parse(rest[k + 1]);
  const { openIdx: mOpen, closeIdx: mClose } = locateModelsBlock(providerKey);
  const indent = indentOf(text, mOpen);
  const rendered = renderModels(modelsObj, indent);
  text = text.slice(0, mOpen) + rendered + text.slice(mClose);
}

process.stdout.write(text);
