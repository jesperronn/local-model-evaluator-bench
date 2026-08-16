# Archived Documentation

This directory contains reference and historical documents from prior development phases.
These documents describe **decisions made**, **handoffs completed**, and **planning work** from earlier work.

**You typically don't need these.** Start with [docs/README](../README.md) instead.

## When to Read These

- **DECISION-*.md** — Why we chose a particular approach. Useful for understanding rationale, not for actionable steps.
- **HANDOFF-*.md** — How prior work was handed off. Completed phases; read for context if inheriting that work.
- **PLAN-*.md** — Planning documents for features under development. Superseded by current docs in parent directory.

## Contents

| File | Phase | Purpose |
|------|-------|---------|
| DECISION-amp-cloud-only.md | Early | Decision to avoid cloud-only models |
| DECISION-interpreter-omlx.md | Aug 2026 | oMLX interpreter choice |
| DECISION-litellm-proxy.md | Aug 2026 | LiteLLM proxy integration decision |
| DECISION-omp-omlx.md | Aug 2026 | OMP vs oMLX tradeoffs |
| DECISION-subagent-orchestrator-candidates.md | Aug 2026 | Subagent orchestrator selection |
| HANDOFF-build-llmrun-omlx.md | Aug 2026 | llmrun + oMLX handoff |
| HANDOFF-hybrid-cloud-local.md | Aug 2026 | Hybrid cloud/local model support |
| HANDOFF-omlx-adapters.md | Aug 2026 | oMLX adapter integration |
| HANDOFF-phone-home-audit.md | Aug 2026 | Phone-home verification handoff |
| PLAN-CLI-UNIFICATION.md | Jul 2026 | CLI tool consolidation planning (partially implemented) |
| PLAN-COPILOT-launcher.md | Jun 2026 | Copilot launcher planning |
| PLAN-LLMRUN-OPENCODE.md | Aug 2026 | llmrun OpenCode integration |
| PLAN-MULTI-MACHINE-PORTABILITY.md | Jul 2026 | Multi-machine setup (reference for bootstrap work) |
| PLAN-PRUNE-OPENCODE.md | Jun 2026 | OpenCode model management |
| PLAN-SPECULATIVE-DECODING.md | Jul 2026 | Speculative decoding exploration |
| PLAN-TROUBLESHOOT.md | Jun 2026 | Troubleshooting infrastructure |

## Current Documentation

For actual usage and workflows, see:
- **[README](../README.md)** — Overview and quick start
- **[WORKFLOWS.md](../WORKFLOWS.md)** — Visual command flowcharts
- **[TOOLS.md](../TOOLS.md)** — All available commands
- **[ONBOARDING.md](../ONBOARDING.md)** — Step-by-step setup
- **[SETUP.md](../SETUP.md)** — Technical LM Studio/CLI reference
- **[FURTHER-READING.md](../FURTHER-READING.md)** — Additional reference materials

## Contributing

When adding new archived documents:
1. Move them here with `git mv docs/FILENAME docs/archived/`
2. Update this README's contents table
3. Ensure the document's first line clearly states its phase and purpose
