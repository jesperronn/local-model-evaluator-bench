# Benchmark Report

**Source:** `all runs (latest per adapter+model+case)`
**Generated:** 2026-06-12 23:55

## Leaderboard — by runtime

| Runtime | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| lms | 1440/2133 | 67.5% | 63.1 |
| ollama | 155/375 | 41.3% | 59.6 |
| mlx | 74/222 | 33.3% | 64.7 |

## Leaderboard — by adapter × model

| Runtime | Adapter | Model | Pass | Pass% | Avg s | Trials |
|---------|---------|-------|------|-------|-------|--------|
| ollama | hermes | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 83.1 | 1 |
| ollama | caveman | qwen3.5:9b | 2/2 | 100.0% | 23.0 | 1 |
| ollama | aider | phi4-mini:latest | 2/2 | 100.0% | 33.0 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 34/34 | 100.0% | 153.3 | 1 |
| lms | opencode | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 79.6 | 1 |
| lms | opencode | qwen/qwen3-coder-next | 34/34 | 100.0% | 35.2 | 1 |
| lms | opencode | qwen/qwen3-coder-30b | 34/34 | 100.0% | 66.3 | 1 |
| lms | opencode | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 105.4 | 1 |
| lms | hermes | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 69.7 | 1 |
| lms | hermes | qwen/qwen3.5-9b | 34/34 | 100.0% | 137.9 | 1 |
| lms | hermes | qwen/qwen3-coder-next | 34/34 | 100.0% | 38.1 | 1 |
| lms | hermes | qwen/qwen3-coder-30b | 34/34 | 100.0% | 91.8 | 1 |
| lms | hermes | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 56.1 | 1 |
| lms | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 | 1 |
| lms | codex | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 53.0 | 1 |
| lms | codex | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 33.3 | 1 |
| lms | codex | qwen/qwen3.5-9b | 34/34 | 100.0% | 146.4 | 1 |
| lms | codex | qwen/qwen3-coder-next | 34/34 | 100.0% | 94.1 | 1 |
| lms | codex | qwen/qwen3-coder-30b | 34/34 | 100.0% | 81.4 | 1 |
| lms | caveman | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 168.0 | 1 |
| lms | caveman | qwen/qwen3.5-9b | 34/34 | 100.0% | 70.7 | 1 |
| lms | caveman | qwen/qwen3-coder-30b | 34/34 | 100.0% | 55.8 | 1 |
| lms | caveman | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 80.0 | 1 |
| lms | caveman | qwen/qwen3-coder-next | 29/30 | 96.7% | 29.1 | 1 |
| lms | caveman | google/gemma-4-12b-qat | 29/30 | 96.7% | 164.2 | 1 |
| lms | hermes | qwen/qwen3.6-35b-a3b | 32/34 | 94.1% | 97.6 | 1 |
| lms | opencode | google/gemma-4-12b-qat | 30/32 | 93.8% | 205.3 | 1 |
| lms | aider | qwen/qwen3.6-35b-a3b | 26/28 | 92.9% | 80.4 | 1 |
| ollama | hermes | gemma4-claude | 29/32 | 90.6% | 71.8 | 1 |
| lms | opencode | google/gemma-4-e2b | 27/30 | 90.0% | 36.7 | 1 |
| ollama | caveman | gemma4-claude | 30/34 | 88.2% | 89.8 | 1 |
| lms | hermes | google/gemma-4-12b-qat | 30/34 | 88.2% | 176.7 | 1 |
| lms | codex | google/gemma-4-26b-a4b-qat | 30/34 | 88.2% | 81.4 | 1 |
| lms | opencode | google/gemma-4-e2b-qat | 28/32 | 87.5% | 44.8 | 1 |
| ollama | caveman | qwen3.6:35b-a3b-coding-mxfp8 | 29/34 | 85.3% | 80.4 | 1 |
| lms | hermes | google/gemma-4-e2b | 21/25 | 84.0% | 31.7 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 28/34 | 82.4% | 210.8 | 1 |
| lms | aider | qwen/qwen3-coder-30b | 26/32 | 81.2% | 9.6 | 1 |
| lms | caveman | google/gemma-4-e2b | 20/25 | 80.0% | 37.0 | 1 |
| lms | hermes | google/gemma-4-e4b | 22/28 | 78.6% | 75.2 | 1 |
| lms | caveman | google/gemma-4-e4b-qat | 22/28 | 78.6% | 46.3 | 1 |
| lms | aider | google/gemma-4-e4b | 22/28 | 78.6% | 33.6 | 1 |
| lms | aider | google/gemma-4-e2b-qat | 22/28 | 78.6% | 19.7 | 1 |
| lms | hermes | google/gemma-4-e2b-qat | 25/32 | 78.1% | 30.4 | 1 |
| lms | hermes | google/gemma-4-e4b-qat | 20/26 | 76.9% | 62.9 | 1 |
| lms | opencode | google/gemma-4-e4b-qat | 22/29 | 75.9% | 60.2 | 1 |
| lms | opencode | qwen/qwen3.5-9b | 25/34 | 73.5% | 147.1 | 1 |
| lms | opencode | google/gemma-4-e4b | 25/34 | 73.5% | 73.8 | 1 |
| lms | aider | qwen/qwen3-coder-next | 23/32 | 71.9% | 16.9 | 1 |
| lms | aider | google/gemma-4-e2b | 17/24 | 70.8% | 20.4 | 1 |
| lms | caveman | google/gemma-4-e4b | 24/34 | 70.6% | 56.6 | 1 |
| lms | aider | google/gemma-4-e4b-qat | 18/28 | 64.3% | 21.4 | 1 |
| lms | codex | google/gemma-4-e4b-qat | 14/24 | 58.3% | 128.6 | 1 |
| lms | aider | qwen/qwen3.5-9b | 16/28 | 57.1% | 51.6 | 1 |
| lms | codex | google/gemma-4-12b-qat | 19/34 | 55.9% | 216.1 | 1 |
| lms | caveman | google/gemma-4-e2b-qat | 15/28 | 53.6% | 21.9 | 1 |
| lms | codex | google/gemma-4-e4b | 15/30 | 50.0% | 100.0 | 1 |
| lms | codex | google/gemma-4-e2b-qat | 12/28 | 42.9% | 50.7 | 1 |
| lms | codex | google/gemma-4-e2b | 13/32 | 40.6% | 37.1 | 1 |
| lms | aider | google/gemma-4-26b-a4b-qat | 11/28 | 39.3% | 49.6 | 1 |
| lms | aider | google/gemma-4-12b-qat | 11/28 | 39.3% | 102.7 | 1 |
| lms | aider | google/gemma-4-12b | 11/28 | 39.3% | 115.6 | 1 |
| lms | aider | qwen/qwen3.6-27b | 10/28 | 35.7% | 256.1 | 1 |
| ollama | hermes | qwen3.5-claude | 8/26 | 30.8% | 141.4 | 1 |
| ollama | hermes | qwen3.5:9b | 1/5 | 20.0% | 190.5 | 1 |
| ollama | caveman | qwen3.5-claude | 4/22 | 18.2% | 123.4 | 1 |
| ollama | claude | gemma4-claude | 2/12 | 16.7% | 290.3 | 1 |
| mlx | hermes | mlx-community/Phi-4-4bit | 2/12 | 16.7% | 28.0 | 3 |
| ollama | codex | phi4-mini:latest | 4/28 | 14.3% | 18.2 | 1 |
| lms | codex | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 4/28 | 14.3% | 7.3 | 1 |
| ollama | opencode | qwen2.5-coder:7b | 2/28 | 7.1% | 0.9 | 1 |
| ollama | opencode | phi4:latest | 2/28 | 7.1% | 0.9 | 1 |
| ollama | opencode | phi4-mini:latest | 2/28 | 7.1% | 1.1 | 1 |
| ollama | codex | qwen2.5-coder:7b | 2/28 | 7.1% | 7.6 | 1 |
| ollama | codex | phi4:latest | 2/28 | 7.1% | 7.2 | 1 |
| mlx | hermes | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 107.3 | 3 |
| mlx | codex | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 0.0 | 3 |
| mlx | codex | mlx-community/Phi-4-4bit | 2/28 | 7.1% | 0.0 | 3 |
| mlx | caveman | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 0.9 | 3 |
| mlx | caveman | mlx-community/Phi-4-4bit | 2/28 | 7.1% | 0.0 | 3 |
| lms | opencode | google/gemma-4-31b-qat | 2/28 | 7.1% | 2.9 | 1 |
| lms | opencode | google/gemma-4-31b | 2/28 | 7.1% | 2.9 | 1 |
| lms | opencode | google/gemma-4-12b | 2/28 | 7.1% | 1.3 | 1 |
| lms | hermes | google/gemma-4-31b-qat | 2/28 | 7.1% | 3.9 | 1 |
| lms | hermes | google/gemma-4-31b | 2/28 | 7.1% | 4.1 | 1 |
| lms | hermes | google/gemma-4-12b | 2/28 | 7.1% | 11.9 | 1 |
| lms | codex | google/gemma-4-31b-qat | 2/28 | 7.1% | 1.3 | 1 |
| lms | codex | google/gemma-4-31b | 2/28 | 7.1% | 1.1 | 1 |
| lms | codex | google/gemma-4-12b | 2/28 | 7.1% | 7.9 | 1 |
| lms | caveman | google/gemma-4-31b-qat | 2/28 | 7.1% | 1.1 | 1 |
| lms | caveman | google/gemma-4-31b | 2/28 | 7.1% | 1.1 | 1 |
| lms | caveman | google/gemma-4-12b | 2/28 | 7.1% | 1.2 | 1 |
| lms | aider | google/gemma-4-31b-qat | 2/28 | 7.1% | 4.6 | 1 |
| lms | aider | google/gemma-4-31b | 2/28 | 7.1% | 4.4 | 1 |
| ollama | hermes | phi4-mini:latest | 0/2 | 0.0% | 19.0 | 1 |
| ollama | caveman | phi4-mini:latest | 0/2 | 0.0% | 17.0 | 1 |
| mlx | caveman | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 0/2 | 0.0% | 0.0 | 1 |

## Leaderboard — by model

| Runtime | Model | Pass | Pass% | Avg s |
|---------|-------|------|-------|-------|
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 34/34 | 100.0% | 153.3 |
| lms | qwen3.6:35b-a3b-coding-mxfp8 | 68/68 | 100.0% | 61.3 |
| lms | qwen/qwen3.6-35b-a3b | 160/164 | 97.6% | 91.8 |
| lms | qwen/qwen3-coder-30b | 162/168 | 96.4% | 61.0 |
| lms | qwen/qwen3-coder-next | 154/164 | 93.9% | 42.7 |
| ollama | qwen3.6:35b-a3b-coding-mxfp8 | 63/68 | 92.6% | 81.8 |
| lms | qwen/qwen3.5-9b | 143/164 | 87.2% | 110.7 |
| lms | google/gemma-4-26b-a4b-qat | 143/164 | 87.2% | 74.5 |
| ollama | gemma4-claude | 61/78 | 78.2% | 110.7 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 28/36 | 77.8% | 189.7 |
| lms | google/gemma-4-12b-qat | 119/158 | 75.3% | 173.0 |
| lms | google/gemma-4-e2b | 98/136 | 72.1% | 32.6 |
| lms | google/gemma-4-e4b-qat | 96/135 | 71.1% | 63.9 |
| lms | google/gemma-4-e4b | 108/154 | 70.1% | 67.8 |
| lms | google/gemma-4-e2b-qat | 102/148 | 68.9% | 33.5 |
| lms | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 38/62 | 61.3% | 56.7 |
| ollama | qwen3.5:9b | 3/7 | 42.9% | 134.7 |
| lms | qwen/qwen3.6-27b | 10/28 | 35.7% | 256.1 |
| ollama | qwen3.5-claude | 12/48 | 25.0% | 132.4 |
| lms | google/gemma-4-12b | 19/140 | 13.6% | 27.6 |
| ollama | phi4-mini:latest | 8/62 | 12.9% | 11.6 |
| mlx | mlx-community/Phi-4-4bit | 6/68 | 8.8% | 4.0 |
| ollama | qwen2.5-coder:7b | 4/56 | 7.1% | 4.2 |
| ollama | phi4:latest | 4/56 | 7.1% | 4.1 |
| mlx | mlx-community/Phi-4-mini-instruct-4bit | 6/84 | 7.1% | 36.1 |
| lms | google/gemma-4-31b-qat | 10/140 | 7.1% | 2.8 |
| lms | google/gemma-4-31b | 10/140 | 7.1% | 2.7 |

## Leaderboard — by adapter

| Adapter | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| hermes | 498/674 | 73.9% | 83.8 |
| caveman | 350/547 | 64.0% | 56.3 |
| opencode | 305/495 | 61.6% | 54.0 |
| aider | 219/398 | 55.0% | 56.0 |
| codex | 295/604 | 48.8% | 53.6 |
| claude | 2/12 | 16.7% | 290.3 |
