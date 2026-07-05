# Deprecated: forge

**Status:** ❌ Deprecated (native binding incompatible)  
**Tested:** 2026-07-05  
**Version:** latest (via `npm install -g @hoangsonw/forge`)  
**Node.js:** v24.18.0

## Problem

Forge crashes on startup with **better-sqlite3 native binding missing**:
- Depends on better-sqlite3 for local SQLite database
- better-sqlite3 requires arm64 native compilation on macOS
- Build fails despite:
  - `npm rebuild --build-from-source`
  - Complete uninstall + reinstall
  - Xcode command-line tools present
- Result: Always crashes with "Could not locate the bindings file" on startup

## Attempts Made

1. **npm rebuild:** `npm rebuild --build-from-source` in forge node_modules — reported success but didn't create binding
2. **Complete reinstall:** `npm uninstall -g @hoangsonw/forge && npm install -g @hoangsonw/forge` — same error
3. **Direct rebuild:** `cd better-sqlite3 && npm rebuild` — still no .node file created
4. **node-gyp rebuild:** Tried manual compilation with node-gyp — failed to find binding.gyp in forge root (dependency issue)

## Root Cause

Better-sqlite3's arm64 native binding is:
- Either not pre-built for this Node.js + macOS combination
- Or the build environment can't compile it (missing C++ toolchain, compiler flags, etc.)
- Prebuilt binaries don't match the installed Node.js version (v24.18.0)

## Why It Fails

Forge starts with:
```
Loading global config...
→ Requires better-sqlite3
→ Calls require('better-sqlite3')
→ Looks for .node file in 12+ standard paths
→ All fail → Crash with "Could not locate bindings"
```

This is a hard blocker — the tool can't start at all.

## If Revisiting

1. Check if better-sqlite3 has a newer pre-built binary for Node v24 + arm64
2. Try older/newer Node.js version that better-sqlite3 supports
3. Install full Xcode (not just command-line tools) for C++ compilation
4. Check better-sqlite3 GitHub for known arm64 macOS issues
5. Consider pinning to an older forge version (if exists) with compatible better-sqlite3

## Files

- Adapter: `adapters/forge-lms.sh`
- Test results: `results/20260705-194154/` and `results/20260705-194245/` (both crashed on startup)
- Verdict in `compat.json`: `"status": "open", "verdict": "maybe-fixable"` (changed to deprecated)

## Alternative

If you need a code editor agent, consider:
- **Forge alternatives:** aider (✅ working), cline (✅ working)
- **Better-sqlite3 alternatives:** Don't exist for forge — it's core to the tool
