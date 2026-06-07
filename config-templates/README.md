# config-templates

The benchmark depends on a little **machine-level config that lives outside this
repo** (in `$HOME`). These templates capture it so a fresh checkout is
reproducible. The canonical home for the real files is your **dotfiles**; copy
from here as a starting point.

Related: [../docs/SETUP.md](../docs/SETUP.md) · [../README.md](../README.md)

| Template | Goes to | For |
|----------|---------|-----|
| `pi-agent-models.json` | `~/.pi/agent/models.json` | **caveman** — defines the `lmstudio` provider (LM Studio's OpenAI endpoint). Add each model id you test to its `models` array. |
| `hermes-config.snippet.yaml` | edit keys in `~/.hermes/config.yaml` | **hermes** — `terminal.backend: local` + `approvals.mode: smart` (no-yolo, fully local). Do **not** overwrite your whole config with this snippet. |

After applying, run `bin/doctor` — it verifies caveman's provider resolves and
hermes is ready. The other tools (`aider`, `opencode`, `codex`) are configured
entirely by their adapters in `adapters/` and need nothing here.
