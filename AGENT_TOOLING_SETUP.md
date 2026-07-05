# Agent Tooling Setup

**Date:** 2026-07-05  
**Version:** 1.0  
**Status:** Active

## Overview

Decision to use strictly local model servers for agent/CLI tooling, with no cloud authentication dependencies.

## Local Model Servers

**Primary:**
- LM Studio (localhost:1234)
- Ollama (localhost:11434)

**Secondary:**
- MLX

## Rejected Tools

- **cursor-agent** — Requires cloud login, incompatible with local-only workflow

## Rationale

All agent tooling must connect exclusively to local model servers without cloud authentication or cloud service dependencies. This aligns with the benchmark's goal of evaluating local models in isolation.

## Configuration Pattern

Environment variables for local model connections:

```bash
# LM Studio
export LM_STUDIO_API_BASE=http://localhost:1234/v1

# Ollama
export OLLAMA_API_BASE=http://localhost:11434
```

## Next Steps

When evaluating new agent tools or CLIs, verify they support local model API endpoints (OpenAI-compatible preferred) and do not require cloud authentication.
