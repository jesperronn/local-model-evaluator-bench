# ccs (Claude Code Switch)

## Metadata

| Field | Value |
|-------|-------|
| **Tool name** | Claude Code Switch |
| **CLI command** | `ccs` |
| **Version** | unknown — not yet evaluated |
| **Adapter script** | not yet written — may not need one if it wraps claude |
| **How it connects** | TBD — ccs switches between Claude Code profiles; investigate if a profile can target a local endpoint |
| **Last reviewed** | never |

## Status

**not evaluated** — low priority; likely piggybacks on the existing claude adapter.

## Investigation notes

`ccs` is a profile switcher for Claude Code. It manages multiple Claude Code identities (API keys, base URLs, etc.) and switches between them. If a profile can be configured with a local `--api-url` (LM Studio or Ollama endpoint), then `ccs` effectively drives Claude Code against local models.

This would not be a new *tool* in the benchmark — it would be a different entry point into the existing claude adapter. Worth investigating whether it simplifies multi-model testing by letting you switch Claude Code profiles without env var juggling.

Things to check:

- List existing profiles: `ccs --list` or `ccs list`
- Config location: `~/.ccs/` or similar
- Does a profile support `baseURL` / `--api-url` override?
- If yes, does running `ccs use <local-profile> && claude ...` behave identically to `adapters/claude-lms.sh`?

If it's just a wrapper around the same mechanism, no separate adapter is needed — document the profile config instead.
