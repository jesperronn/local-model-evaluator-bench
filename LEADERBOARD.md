# Benchmark Report

**Source:** `all runs (latest per adapter+model+case)`
**Generated:** 2026-09-12 08:02

## Leaderboard — by runtime

| Runtime | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| litellm-proxy | 6/6 | 100.0% | 91.3 |
| mtplx | 226/250 | 90.4% | 78.2 |
| omlx | 229/258 | 88.8% | 29.8 |

## Leaderboard — by adapter × model

| Runtime | Adapter | Model | Pass | Pass% | Avg s | Trials |
|---------|---------|-------|------|-------|-------|--------|
| omlx | vibe | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 18.3 | 1 |
| omlx | vibe | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 14.7 | 1 |
| omlx | qwen | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 25.3 | 1 |
| omlx | qwen | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 26.0 | 1 |
| omlx | pi | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 27.3 | 1 |
| omlx | pi | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 8.7 | 1 |
| omlx | openhands | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 44.0 | 1 |
| omlx | openhands | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 38.0 | 1 |
| omlx | opencode-orch | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 53.0 | 1 |
| omlx | opencode-orch | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 44.0 | 1 |
| omlx | opencode | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 18.0 | 1 |
| omlx | opencode | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 16.0 | 1 |
| omlx | omp | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 75.7 | 1 |
| omlx | omp | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 10.7 | 1 |
| omlx | nanocoder | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 10.0 | 1 |
| omlx | nanocoder | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 6.3 | 1 |
| omlx | mini-swe-agent | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 156.3 | 1 |
| omlx | mini-swe-agent | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 132.7 | 1 |
| omlx | interpreter | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 14.0 | 1 |
| omlx | interpreter | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 16.3 | 1 |
| omlx | gptme | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 21.3 | 1 |
| omlx | gptme | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 47.3 | 1 |
| omlx | goose | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 24.0 | 1 |
| omlx | goose | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 12.0 | 1 |
| omlx | codex | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 17.3 | 1 |
| omlx | codex | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 16.0 | 1 |
| omlx | cn | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 10.7 | 1 |
| omlx | cn | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 11.0 | 1 |
| omlx | cline | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 31.0 | 1 |
| omlx | claude | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 13.3 | 1 |
| omlx | claude | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 11.0 | 1 |
| omlx | caveman | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 36.3 | 1 |
| omlx | caveman | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 15.0 | 1 |
| omlx | aider | Ornith-1.5-35B-A3B-MLX-6bit | 6/6 | 100.0% | 9.0 | 1 |
| omlx | aider | Ornith-1.5-35B-A3B-MLX-4bit | 6/6 | 100.0% | 8.7 | 1 |
| mtplx | vibe | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 30.3 | 1 |
| mtplx | qwen | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 69.3 | 1 |
| mtplx | pi | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 8.7 | 1 |
| mtplx | pi | mtplx-flash-next-optimized-speed | 44/44 | 100.0% | 48.4 | 1 |
| mtplx | opencode-orch | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 116.7 | 1 |
| mtplx | opencode | mtplx-flash-next-optimized-speed | 44/44 | 100.0% | 57.2 | 1 |
| mtplx | omp | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 10.0 | 1 |
| mtplx | interpreter | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 147.0 | 1 |
| mtplx | hermes | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 94.3 | 1 |
| mtplx | gptme | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 118.0 | 1 |
| mtplx | goose | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 40.0 | 1 |
| mtplx | codex | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 53.3 | 1 |
| mtplx | cn | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 24.0 | 1 |
| mtplx | cline | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 42.3 | 1 |
| mtplx | claude | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 115.0 | 1 |
| mtplx | caveman | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 78.0 | 1 |
| mtplx | aider | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 60.7 | 1 |
| litellm-proxy | cn | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 91.3 | 1 |
| omlx | cline | Ornith-1.5-35B-A3B-MLX-6bit | 5/6 | 83.3% | 102.0 | 1 |
| mtplx | mini-swe-agent | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 32/42 | 76.2% | 194.8 | 1 |
| mtplx | openhands | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 4/6 | 66.7% | 104.7 | 1 |
| mtplx | opencode | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 4/6 | 66.7% | 82.0 | 1 |
| mtplx | nanocoder | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 4/6 | 66.7% | 41.7 | 1 |
| omlx | omp | Qwen3.5-2B-bf16 | 2/6 | 33.3% | 61.0 | 1 |
| omlx | hermes | Ornith-1.5-35B-A3B-MLX-6bit | 2/6 | 33.3% | 2.0 | 1 |
| omlx | hermes | Ornith-1.5-35B-A3B-MLX-4bit | 2/6 | 33.3% | 2.0 | 1 |
| omlx | forge | Ornith-1.5-35B-A3B-MLX-6bit | 2/6 | 33.3% | 4.0 | 1 |
| omlx | forge | Ornith-1.5-35B-A3B-MLX-4bit | 2/6 | 33.3% | 5.3 | 1 |
| omlx | copilot | Ornith-1.5-35B-A3B-MLX-6bit | 2/6 | 33.3% | 32.3 | 1 |
| omlx | copilot | Ornith-1.5-35B-A3B-MLX-4bit | 2/6 | 33.3% | 34.7 | 1 |
| mtplx | forge | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 2/6 | 33.3% | 28.3 | 1 |
| mtplx | copilot | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 2/6 | 33.3% | 36.7 | 1 |

## Leaderboard — by model

| Runtime | Model | Pass | Pass% | Avg s |
|---------|-------|------|-------|-------|
| mtplx | mtplx-flash-next-optimized-speed | 88/88 | 100.0% | 52.8 |
| litellm-proxy | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 6/6 | 100.0% | 91.3 |
| omlx | Ornith-1.5-35B-A3B-MLX-4bit | 114/126 | 90.5% | 24.2 |
| omlx | Ornith-1.5-35B-A3B-MLX-6bit | 113/126 | 89.7% | 34.0 |
| mtplx | ornith-ai-ornith-1.5-35b-a3b-mlx-4bit | 138/162 | 85.2% | 86.7 |
| omlx | Qwen3.5-2B-bf16 | 2/6 | 33.3% | 61.0 |

## Leaderboard — by adapter

| Adapter | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| vibe | 18/18 | 100.0% | 21.1 |
| qwen | 18/18 | 100.0% | 40.2 |
| pi | 62/62 | 100.0% | 34.0 |
| opencode-orch | 18/18 | 100.0% | 71.2 |
| interpreter | 18/18 | 100.0% | 59.1 |
| gptme | 18/18 | 100.0% | 62.2 |
| goose | 18/18 | 100.0% | 25.3 |
| codex | 18/18 | 100.0% | 28.9 |
| cn | 24/24 | 100.0% | 34.2 |
| claude | 18/18 | 100.0% | 46.4 |
| caveman | 18/18 | 100.0% | 43.1 |
| aider | 18/18 | 100.0% | 26.1 |
| opencode | 60/62 | 96.8% | 49.3 |
| cline | 17/18 | 94.4% | 58.4 |
| openhands | 16/18 | 88.9% | 62.2 |
| nanocoder | 16/18 | 88.9% | 19.3 |
| omp | 20/24 | 83.3% | 39.3 |
| mini-swe-agent | 44/54 | 81.5% | 178.1 |
| hermes | 10/18 | 55.6% | 32.8 |
| forge | 6/18 | 33.3% | 12.6 |
| copilot | 6/18 | 33.3% | 34.6 |
