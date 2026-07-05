# Deprecated: mini-swe-agent

**Status:** ❌ Deprecated (non-interactive stdin incompatible)  
**Tested:** 2026-07-05  
**Version:** 2.4.2

## Problem

mini-swe-agent v2 (the latest version) has **non-interactive stdin incompatibility**:
- Always prompts for model/API key setup, even when:
  - `--model openai/model-id` is passed
  - `MINI_CONFIG_INTERACTIVE=0` is set
  - `.env` file pre-configured with model + API key
  - Stdin is piped (non-TTY mode)
- When stdin is piped, the tool treats it as input to the interactive prompt, not the task
- Result: Always times out (stall phase, 180s warmup exceeded)

## Attempts Made

1. **Environment variable:** `MINI_CONFIG_INTERACTIVE=0` — ignored
2. **Config file:** `.env` with `MSWEA_MODEL_*` vars — ignored  
3. **Command-line flag:** `--model openai/...` — tool still prompts
4. **Root cause:** Tool does early initialization before CLI arg parsing, always prompts if stdin is piped

## Why It Fails

The adapter spec requires:
```bash
echo "task description" | adapter-name
```

But mini-swe-agent v2 needs:
```bash
mini-swe-agent  # interactive terminal only, no piped input
```

This is a design mismatch, not a configuration issue.

## If Revisiting

1. Check v3+ release notes — may have fixed non-interactive mode
2. Contact maintainers about non-TTY stdin support
3. Consider patching the v2 source to skip interactive setup
4. Alternative: Use v1 (if still maintained, but older/simpler)

## Files

- Adapter: `adapters/mini-swe-agent-lms.sh`
- Test results: `results/20260705-115419/` (timeout after 180s warmup)
- Verdict in `compat.json`: `"status": "open", "verdict": "fixable"` (changed to deprecated)

## Config Left Behind

Pre-configured `.env` at:
```
~/Library/Application Support/mini-swe-agent/.env
MSWEA_MODEL_NAME=openai/qwen/qwen3.5-9b
MSWEA_MODEL_API_BASE=http://localhost:1234/v1
MSWEA_MODEL_API_KEY=lm-studio
```

Can be used for manual interactive testing if you decide to revisit.
