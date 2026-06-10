# Benchmark Report

**Source:** `all runs (latest per adapter+model+case)`
**Generated:** 2026-06-10 19:31

## Leaderboard — by runtime

| Runtime | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| mlx | 34/34 | 100.0% | 98.9 |
| lms | 1386/2100 | 66.0% | 54.0 |

## Leaderboard — by adapter × model

| Runtime | Adapter | Model | Pass | Pass% | Avg s | Trials |
|---------|---------|-------|------|-------|-------|--------|
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 98.9 | 1 |
| lms | opencode | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 59.8 | 1 |
| lms | opencode | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 105.4 | 1 |
| lms | hermes | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 69.7 | 1 |
| lms | hermes | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 30.6 | 1 |
| lms | hermes | qwen/qwen3-coder-next | 34/34 | 100.0% | 42.2 | 1 |
| lms | hermes | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 56.1 | 1 |
| lms | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 | 1 |
| lms | codex | qwen3.6:35b-a3b-coding-mxfp8 | 34/34 | 100.0% | 53.0 | 1 |
| lms | codex | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 32.7 | 1 |
| lms | codex | qwen/qwen3.5-9b | 34/34 | 100.0% | 110.6 | 1 |
| lms | codex | qwen/qwen3-coder-next | 34/34 | 100.0% | 94.1 | 1 |
| lms | codex | qwen/qwen3-coder-30b | 34/34 | 100.0% | 81.4 | 1 |
| lms | caveman | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 37.1 | 1 |
| lms | caveman | qwen/qwen3-coder-30b | 34/34 | 100.0% | 55.8 | 1 |
| lms | caveman | google/gemma-4-26b-a4b-qat | 34/34 | 100.0% | 80.0 | 1 |
| lms | opencode | qwen/qwen3-coder-30b | 33/34 | 97.1% | 64.4 | 1 |
| lms | hermes | qwen/qwen3.5-9b | 33/34 | 97.1% | 154.4 | 1 |
| lms | hermes | qwen/qwen3-coder-30b | 33/34 | 97.1% | 91.6 | 1 |
| lms | caveman | qwen/qwen3.5-9b | 30/31 | 96.8% | 72.3 | 1 |
| lms | caveman | qwen/qwen3-coder-next | 29/30 | 96.7% | 29.1 | 1 |
| lms | caveman | google/gemma-4-12b-qat | 29/30 | 96.7% | 164.2 | 1 |
| lms | opencode | google/gemma-4-12b-qat | 30/32 | 93.8% | 205.3 | 1 |
| lms | opencode | google/gemma-4-e2b | 27/30 | 90.0% | 36.7 | 1 |
| lms | hermes | google/gemma-4-12b-qat | 30/34 | 88.2% | 176.7 | 1 |
| lms | codex | google/gemma-4-26b-a4b-qat | 30/34 | 88.2% | 81.4 | 1 |
| lms | opencode | google/gemma-4-e2b-qat | 28/32 | 87.5% | 44.8 | 1 |
| lms | hermes | google/gemma-4-e2b | 21/25 | 84.0% | 31.3 | 1 |
| lms | aider | qwen/qwen3-coder-30b | 26/32 | 81.2% | 9.6 | 1 |
| lms | caveman | google/gemma-4-e2b | 20/25 | 80.0% | 37.0 | 1 |
| lms | hermes | google/gemma-4-e4b | 22/28 | 78.6% | 75.2 | 1 |
| lms | caveman | google/gemma-4-e4b-qat | 22/28 | 78.6% | 46.3 | 1 |
| lms | aider | google/gemma-4-e4b | 22/28 | 78.6% | 33.6 | 1 |
| lms | aider | google/gemma-4-e2b-qat | 22/28 | 78.6% | 19.7 | 1 |
| lms | hermes | google/gemma-4-e4b-qat | 20/26 | 76.9% | 62.9 | 1 |
| lms | opencode | google/gemma-4-e4b-qat | 22/29 | 75.9% | 60.2 | 1 |
| lms | opencode | google/gemma-4-e4b | 25/34 | 73.5% | 73.8 | 1 |
| lms | aider | qwen/qwen3-coder-next | 23/32 | 71.9% | 16.9 | 1 |
| lms | aider | qwen/qwen3.5-9b | 20/28 | 71.4% | 17.9 | 1 |
| lms | aider | google/gemma-4-e2b | 17/24 | 70.8% | 20.2 | 1 |
| lms | caveman | google/gemma-4-e4b | 24/34 | 70.6% | 56.6 | 1 |
| lms | aider | qwen/qwen3.6-35b-a3b | 22/32 | 68.8% | 59.8 | 1 |
| lms | opencode | qwen/qwen3.5-9b | 23/34 | 67.6% | 48.9 | 1 |
| lms | aider | google/gemma-4-e4b-qat | 18/28 | 64.3% | 21.4 | 1 |
| lms | hermes | google/gemma-4-e2b-qat | 20/32 | 62.5% | 21.9 | 1 |
| lms | codex | google/gemma-4-e4b-qat | 14/24 | 58.3% | 128.6 | 1 |
| lms | codex | google/gemma-4-12b-qat | 19/34 | 55.9% | 216.1 | 1 |
| lms | caveman | google/gemma-4-e2b-qat | 15/28 | 53.6% | 21.9 | 1 |
| lms | codex | google/gemma-4-e4b | 15/30 | 50.0% | 100.0 | 1 |
| lms | codex | google/gemma-4-e2b-qat | 12/28 | 42.9% | 50.7 | 1 |
| lms | codex | google/gemma-4-e2b | 13/32 | 40.6% | 36.7 | 1 |
| lms | aider | google/gemma-4-26b-a4b-qat | 11/28 | 39.3% | 49.6 | 1 |
| lms | aider | google/gemma-4-12b-qat | 11/28 | 39.3% | 102.7 | 1 |
| lms | aider | google/gemma-4-12b | 11/28 | 39.3% | 115.6 | 1 |
| lms | codex | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 4/28 | 14.3% | 7.3 | 1 |
| lms | opencode | qwen/qwen3-coder-next | 2/28 | 7.1% | 1.0 | 1 |
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

## Leaderboard — by model

| Runtime | Model | Pass | Pass% | Avg s |
|---------|-------|------|-------|-------|
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 98.9 |
| lms | qwen3.6:35b-a3b-coding-mxfp8 | 68/68 | 100.0% | 61.3 |
| lms | qwen/qwen3-coder-30b | 160/168 | 95.2% | 60.6 |
| lms | qwen/qwen3.6-35b-a3b | 158/168 | 94.0% | 44.0 |
| lms | google/gemma-4-26b-a4b-qat | 143/164 | 87.2% | 74.5 |
| lms | qwen/qwen3.5-9b | 140/161 | 87.0% | 80.8 |
| lms | qwen/qwen3-coder-next | 122/158 | 77.2% | 36.7 |
| lms | google/gemma-4-12b-qat | 119/158 | 75.3% | 173.0 |
| lms | google/gemma-4-e2b | 98/136 | 72.1% | 32.4 |
| lms | google/gemma-4-e4b-qat | 96/135 | 71.1% | 63.9 |
| lms | google/gemma-4-e4b | 108/154 | 70.1% | 67.8 |
| lms | google/gemma-4-e2b-qat | 97/148 | 65.5% | 31.8 |
| lms | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 38/62 | 61.3% | 56.7 |
| lms | google/gemma-4-12b | 19/140 | 13.6% | 27.6 |
| lms | google/gemma-4-31b-qat | 10/140 | 7.1% | 2.8 |
| lms | google/gemma-4-31b | 10/140 | 7.1% | 2.7 |

## Leaderboard — by adapter

| Adapter | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| hermes | 389/501 | 77.6% | 64.8 |
| caveman | 277/392 | 70.7% | 46.4 |
| opencode | 264/405 | 65.2% | 54.4 |
| codex | 283/464 | 61.0% | 66.9 |
| aider | 207/372 | 55.6% | 36.6 |
