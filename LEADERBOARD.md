# Benchmark Report

**Source:** `all runs (latest per adapter+model+case)`
**Generated:** 2026-06-12 21:01

## Leaderboard — by runtime

| Runtime | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| lms | 1259/2107 | 59.8% | 50.9 |
| ollama | 155/375 | 41.3% | 59.6 |
| mlx | 46/186 | 24.7% | 34.2 |

## Leaderboard — by adapter × model

| Runtime | Adapter | Model | Pass | Pass% | Avg s | Trials |
|---------|---------|-------|------|-------|-------|--------|
| ollama | hermes | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 83.1 | 1 |
| ollama | caveman | qwen3.5:9b | 2/2 | 100.0% | 23.0 | 1 |
| ollama | aider | phi4-mini:latest | 2/2 | 100.0% | 33.0 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 98.9 | 1 |
| lms | opencode | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 70.3 | 1 |
| lms | opencode | qwen/qwen3-coder-next | 34/34 | 100.0% | 35.2 | 1 |
| lms | opencode | qwen/qwen3-coder-30b | 34/34 | 100.0% | 75.0 | 1 |
| lms | opencode | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 137.6 | 1 |
| lms | hermes | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 69.7 | 1 |
| lms | hermes | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 36.9 | 1 |
| lms | hermes | qwen/qwen3.5-9b | 34/34 | 100.0% | 126.6 | 1 |
| lms | hermes | qwen/qwen3-coder-next | 34/34 | 100.0% | 38.1 | 1 |
| lms | hermes | qwen/qwen3-coder-30b | 34/34 | 100.0% | 91.8 | 1 |
| lms | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 | 1 |
| lms | codex | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 53.0 | 1 |
| lms | codex | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 32.7 | 1 |
| lms | codex | qwen/qwen3.5-9b | 34/34 | 100.0% | 116.7 | 1 |
| lms | codex | qwen/qwen3-coder-next | 34/34 | 100.0% | 94.1 | 1 |
| lms | codex | qwen/qwen3-coder-30b | 34/34 | 100.0% | 81.4 | 1 |
| lms | caveman | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 37.1 | 1 |
| lms | caveman | qwen/qwen3-coder-30b | 34/34 | 100.0% | 55.8 | 1 |
| lms | caveman | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 80.0 | 1 |
| lms | caveman | qwen/qwen3.5-9b | 30/31 | 96.8% | 73.0 | 1 |
| lms | caveman | qwen/qwen3-coder-next | 29/30 | 96.7% | 29.1 | 1 |
| lms | caveman | google/gemma-4-12b-qat | 29/30 | 96.7% | 164.2 | 1 |
| lms | opencode | qwen/qwen3.5-9b | 32/34 | 94.1% | 81.1 | 1 |
| ollama | hermes | gemma4-claude | 29/32 | 90.6% | 71.8 | 1 |
| lms | opencode | google/gemma-4-e2b | 27/30 | 90.0% | 36.7 | 1 |
| ollama | caveman | gemma4-claude | 30/34 | 88.2% | 89.8 | 1 |
| lms | codex | google/gemma-4-26b-a4b-qat | 30/34 | 88.2% | 81.4 | 1 |
| ollama | caveman | qwen3.6:35b-a3b-coding-mxfp8 | 29/34 | 85.3% | 80.4 | 1 |
| lms | aider | qwen/qwen3-coder-30b | 26/32 | 81.2% | 13.8 | 1 |
| lms | caveman | google/gemma-4-e2b | 20/25 | 80.0% | 37.0 | 1 |
| lms | caveman | google/gemma-4-e4b-qat | 22/28 | 78.6% | 46.3 | 1 |
| lms | aider | google/gemma-4-e4b | 22/28 | 78.6% | 33.6 | 1 |
| lms | aider | google/gemma-4-e2b-qat | 22/28 | 78.6% | 17.1 | 1 |
| lms | opencode | google/gemma-4-e4b-qat | 22/29 | 75.9% | 60.2 | 1 |
| lms | opencode | google/gemma-4-e4b | 25/34 | 73.5% | 78.9 | 1 |
| lms | aider | qwen/qwen3-coder-next | 23/32 | 71.9% | 16.9 | 1 |
| lms | aider | qwen/qwen3.5-9b | 20/28 | 71.4% | 22.2 | 1 |
| lms | aider | google/gemma-4-e2b | 17/24 | 70.8% | 20.4 | 1 |
| lms | caveman | google/gemma-4-e4b | 24/34 | 70.6% | 56.6 | 1 |
| lms | aider | qwen/qwen3.6-35b-a3b | 22/32 | 68.8% | 65.8 | 1 |
| lms | aider | google/gemma-4-e4b-qat | 18/28 | 64.3% | 21.4 | 1 |
| lms | codex | google/gemma-4-e4b-qat | 14/24 | 58.3% | 128.6 | 1 |
| lms | codex | google/gemma-4-12b-qat | 19/34 | 55.9% | 216.1 | 1 |
| lms | codex | google/gemma-4-e4b | 15/30 | 50.0% | 100.0 | 1 |
| lms | opencode | google/gemma-4-e2b-qat | 12/28 | 42.9% | 69.6 | 1 |
| lms | codex | google/gemma-4-e2b | 13/32 | 40.6% | 37.1 | 1 |
| lms | aider | google/gemma-4-26b-a4b-qat | 11/28 | 39.3% | 49.6 | 1 |
| lms | aider | google/gemma-4-12b-qat | 11/28 | 39.3% | 102.7 | 1 |
| lms | aider | google/gemma-4-12b | 11/28 | 39.3% | 115.6 | 1 |
| lms | aider | qwen/qwen3.6-27b | 10/28 | 35.7% | 253.6 | 1 |
| lms | codex | google/gemma-4-e2b-qat | 9/26 | 34.6% | 55.8 | 1 |
| lms | hermes | google/gemma-4-e2b-qat | 9/28 | 32.1% | 23.3 | 1 |
| lms | caveman | google/gemma-4-e2b-qat | 7/22 | 31.8% | 39.7 | 1 |
| ollama | hermes | qwen3.5-claude | 8/26 | 30.8% | 141.4 | 1 |
| ollama | hermes | qwen3.5:9b | 1/5 | 20.0% | 190.5 | 1 |
| ollama | caveman | qwen3.5-claude | 4/22 | 18.2% | 123.4 | 1 |
| ollama | claude | gemma4-claude | 2/12 | 16.7% | 290.3 | 1 |
| mlx | hermes | mlx-community/Phi-4-4bit | 2/12 | 16.7% | 28.0 | 3 |
| ollama | codex | phi4-mini:latest | 4/28 | 14.3% | 18.2 | 1 |
| lms | hermes | google/gemma-4-e2b | 4/28 | 14.3% | 4.8 | 1 |
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
| lms | opencode | google/gemma-4-31b | 2/28 | 7.1% | 3.1 | 1 |
| lms | opencode | google/gemma-4-12b-qat | 2/28 | 7.1% | 2.6 | 1 |
| lms | opencode | google/gemma-4-12b | 2/28 | 7.1% | 3.2 | 1 |
| lms | hermes | google/gemma-4-e4b-qat | 2/28 | 7.1% | 3.6 | 1 |
| lms | hermes | google/gemma-4-e4b | 2/28 | 7.1% | 3.3 | 1 |
| lms | hermes | google/gemma-4-31b-qat | 2/28 | 7.1% | 3.9 | 1 |
| lms | hermes | google/gemma-4-31b | 2/28 | 7.1% | 4.1 | 1 |
| lms | hermes | google/gemma-4-26b-a4b-qat | 2/28 | 7.1% | 4.9 | 1 |
| lms | hermes | google/gemma-4-12b-qat | 2/28 | 7.1% | 3.7 | 1 |
| lms | hermes | google/gemma-4-12b | 2/28 | 7.1% | 11.9 | 1 |
| lms | codex | google/gemma-4-31b-qat | 2/28 | 7.1% | 1.3 | 1 |
| lms | codex | google/gemma-4-31b | 2/28 | 7.1% | 1.3 | 1 |
| lms | codex | google/gemma-4-12b | 2/28 | 7.1% | 1.0 | 1 |
| lms | caveman | google/gemma-4-31b-qat | 2/28 | 7.1% | 1.1 | 1 |
| lms | caveman | google/gemma-4-31b | 2/28 | 7.1% | 1.1 | 1 |
| lms | caveman | google/gemma-4-12b | 2/28 | 7.1% | 1.2 | 1 |
| lms | aider | google/gemma-4-31b-qat | 2/28 | 7.1% | 4.6 | 1 |
| lms | aider | google/gemma-4-31b | 2/28 | 7.1% | 4.4 | 1 |
| ollama | hermes | phi4-mini:latest | 0/2 | 0.0% | 19.0 | 1 |
| ollama | caveman | phi4-mini:latest | 0/2 | 0.0% | 17.0 | 1 |

## Leaderboard — by model

| Runtime | Model | Pass | Pass% | Avg s |
|---------|-------|------|-------|-------|
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 98.9 |
| lms | qwen3.6:35b-a3b-coding-mxfp8 | 68/68 | 100.0% | 61.3 |
| lms | qwen/qwen3-coder-30b | 162/168 | 96.4% | 63.6 |
| lms | qwen/qwen3.6-35b-a3b | 158/168 | 94.0% | 48.6 |
| lms | qwen/qwen3-coder-next | 154/164 | 93.9% | 42.7 |
| lms | qwen/qwen3.5-9b | 150/161 | 93.2% | 83.9 |
| ollama | qwen3.6:35b-a3b-coding-mxfp8 | 63/68 | 92.6% | 81.8 |
| ollama | gemma4-claude | 61/78 | 78.2% | 110.7 |
| lms | google/gemma-4-26b-a4b-qat | 111/158 | 70.3% | 70.7 |
| lms | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 38/62 | 61.3% | 56.7 |
| lms | google/gemma-4-e2b | 81/139 | 58.3% | 27.2 |
| lms | google/gemma-4-e4b | 88/154 | 57.1% | 54.5 |
| lms | google/gemma-4-e4b-qat | 78/137 | 56.9% | 52.0 |
| lms | google/gemma-4-e2b-qat | 59/132 | 44.7% | 41.1 |
| ollama | qwen3.5:9b | 3/7 | 42.9% | 134.7 |
| lms | google/gemma-4-12b-qat | 63/148 | 42.6% | 97.8 |
| lms | qwen/qwen3.6-27b | 10/28 | 35.7% | 253.6 |
| ollama | qwen3.5-claude | 12/48 | 25.0% | 132.4 |
| lms | google/gemma-4-12b | 19/140 | 13.6% | 26.6 |
| ollama | phi4-mini:latest | 8/62 | 12.9% | 11.6 |
| mlx | mlx-community/Phi-4-4bit | 6/68 | 8.8% | 4.0 |
| ollama | qwen2.5-coder:7b | 4/56 | 7.1% | 4.2 |
| ollama | phi4:latest | 4/56 | 7.1% | 4.1 |
| mlx | mlx-community/Phi-4-mini-instruct-4bit | 6/84 | 7.1% | 36.1 |
| lms | google/gemma-4-31b-qat | 10/140 | 7.1% | 2.8 |
| lms | google/gemma-4-31b | 10/140 | 7.1% | 2.8 |

## Leaderboard — by adapter

| Adapter | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| caveman | 338/536 | 63.1% | 50.6 |
| opencode | 268/487 | 55.0% | 41.2 |
| aider | 219/402 | 54.5% | 52.8 |
| hermes | 341/629 | 54.2% | 52.7 |
| codex | 292/602 | 48.5% | 52.0 |
| claude | 2/12 | 16.7% | 290.3 |
