# Agent instructions

## Prefer repo docs over tool-specific memory

Durable knowledge about this project — conventions, policies, decisions,
tool/adapter status, setup notes — belongs in version-controlled files under
`docs/` (or the relevant script/config), not in an AI tool's private memory
system. Memory is invisible to other contributors and to other tools, and it
silently goes stale.

When you learn or decide something worth remembering for next time, write it
to the appropriate doc instead of (or in addition to) saving it as memory:

- Policy/process decisions → `docs/WORKFLOW.md` (`## Conventions`)
- Tool/adapter evaluation notes → `docs/tools/<name>.md` (e.g., [`docs/tools/hwprofile.md`](docs/tools/hwprofile.md) for hardware detection)
- One-off "should we adopt X" investigations → `docs/DECISION-<topic>.md`
- Ideas not yet implemented → `docs/FUTURE-IDEAS.md`
- Setup/environment specifics → `docs/SETUP.md`

Only use your own memory for things that are genuinely session-scoped or
about *how you personally work with this user* — not facts about the project
itself. If in doubt, put it in the repo.
