# Adapter Testing Results — 2026-07-05

Test run on adapters not previously tested: Claude, Mini-swe-agent, Forge.

**Test Model:** liquid/lfm2-24b-a2b (LMS runtime)
**Test Cases:** smoke-00-hello, smoke-01-edit-file, smoke-02-numbers
**Run IDs:** 20260705-112308 (claude), 20260705-115419 (mini-swe-agent), 20260705-115601 (forge)

---

## Claude Adapter — ❌ **UNFIXABLE**

**Status:** Tool execution broken
- Reaches model: ✓ Yes
- File creation: ✗ No (SDK claims success, files don't exist)
- **Root cause:** Stainless SDK expects tool execution feedback that LM Studio's OpenAI endpoint doesn't provide

**Evidence:**
```
smoke-00-hello: 0/2 PASS (claims success in text, file missing in sandbox)
smoke-01-edit-file: 0/2 PASS (refuses edit)
```

**Verdict:** Unfixable without Stainless SDK or LM Studio changes

**Actions Taken:**
- Added to compat.json with `status=open` and verdict `unfixable`
- Documented in ADAPTER-SETUP.md as ❌ incompatible

---

## Mini-swe-agent — ⚠️ **FIXABLE** (Config Issue)

**Status:** Interactive setup blocker
- Reaches model: ✓ Yes  
- Gets stuck: ✓ Yes (waiting for config input)
- Times out: ✓ Yes (180s warmup exceeded)

**Root cause:** v2 requires config setup, but stdin is piped (non-interactive)
```
Loading global config from '~/.config/mini-swe-agent/.env'
Warning: Input is not a terminal (fd=0).
To get started, we need to set up your global config file.
Enter your default model (e.g., anthropic/claude-opus-4-6-20260205):
[TIMEOUT after 180s]
```

**Fix Options:**
1. Pre-create config: `mkdir -p ~/.config/mini-swe-agent && echo "MODEL=openai/qwen3.6-35b" > ~/.config/mini-swe-agent/config.json`
2. Modify adapter to set `MINI_SWE_CONFIG` env var with hardcoded model
3. Use `--no-interactive` flag if available in v2

**Actions Taken:**
- Added to compat.json with `status=open` and verdict `fixable`
- Documented the fix approach above

---

## Forge — ⚠️ **MAYBE FIXABLE** (Build Issue)

**Status:** Crashed on startup
- Reaches model: Partial (loads model, then crashes)
- Error: Node.js native binding missing

**Root cause:** better-sqlite3 arm64 bindings not compiled
```
Error: Could not locate the bindings file.
→ /Users/jesper/.npm-global/lib/node_modules/@hoangsonw/forge/node_modules/better-sqlite3/...
```

**Fix Options:**
1. Rebuild bindings: `cd ~/.npm-global/lib/node_modules/@hoangsonw/forge && npm rebuild --build-from-source`
2. Reinstall forge: `npm uninstall -g @hoangsonw/forge && npm install -g @hoangsonw/forge`
3. Install build tools: `xcode-select --install` (if missing)

**Actions Taken:**
- Added to compat.json with `status=open` and verdict `maybe-fixable`
- Documented rebuild command above

---

## Summary Table

| Adapter | Reaches Model | Tool Works | Root Cause | Fixable | Status |
|---------|---|---|---|---|---|
| **claude** | ✓ Yes | ❌ No | SDK/API mismatch | ❌ No | Document incompatibility |
| **mini-swe-agent** | ✓ Yes | ❌ No (config prompt) | Non-interactive stdin | ✅ Yes | Pre-create config file |
| **forge** | Partial | ❌ No (binding missing) | Native bindings not compiled | ⚠️ Maybe | Try npm rebuild |

---

## Related Documentation

- [ADAPTER-SETUP.md](ADAPTER-SETUP.md) — Compatibility matrix (✅ recommended, ⚠️ limited, ❌ incompatible)
- [TESTING-STRATEGY.md](TESTING-STRATEGY.md) — Testing funnel (L0–L3)
- [compat.json](../compat.json) — Full compatibility tracking with verdicts
