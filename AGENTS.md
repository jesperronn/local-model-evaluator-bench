# Agent instructions

## Never push branches unless explicitly asked

Committing locally is fine; pushing (or opening a PR) is a separate action
the user must request explicitly each time. "Approve this plan" or "commit
this" does not imply "push it."

## Prefer repo docs over tool-specific memory

Durable project knowledge (conventions, policies, decisions, tool/adapter
status, setup notes) belongs in version-controlled files, not an AI tool's
private memory — memory is invisible to other contributors/tools and goes
stale silently.

- Policy/process decisions → `docs/WORKFLOW.md` (`## Conventions`)
- Tool/adapter evaluation notes → `docs/tools/<name>.md`
- One-off "should we adopt X" investigations → `docs/DECISION-<topic>.md`
- Ideas not yet implemented → `docs/FUTURE-IDEAS.md`
- Setup/environment specifics → `docs/SETUP.md`

Use personal memory only for session-scoped notes or how you personally
work with this user — not facts about the project itself.
