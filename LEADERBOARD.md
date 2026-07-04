# Benchmark Report

**Source:** `all runs (latest per adapter+model+case)`
**Generated:** 2026-07-04 20:50

## Leaderboard — by runtime

| Runtime | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| lms | 3790/5460 | 69.4% | 95.0 |
| ollama | 892/1321 | 67.5% | 76.8 |
| mlx | 374/654 | 57.2% | 61.4 |

## Leaderboard — by adapter × model

| Runtime | Adapter | Model | Pass | Pass% | Avg s | Trials |
|---------|---------|-------|------|-------|-------|--------|
| ollama | pi | qwen3.6:35b-a3b-coding-mxfp8 | 6/6 | 100.0% | 81.0 | 1 |
| ollama | opencode | gemma4-26b-qat | 34/34 | 100.0% | 125.4 | 1 |
| ollama | opencode | gemma4-12b-mlx | 6/6 | 100.0% | 98.3 | 1 |
| ollama | interpreter | qwen3.6:35b-mlx | 38/38 | 100.0% | 73.6 | 1 |
| ollama | interpreter | gemma4-12b-mlx | 6/6 | 100.0% | 69.0 | 1 |
| ollama | hermes | gemma4-12b-mlx | 6/6 | 100.0% | 64.0 | 1 |
| ollama | caveman | qwen3.6:35b-a3b-coding-mxfp8 | 2/2 | 100.0% | 38.0 | 1 |
| ollama | caveman | qwen3.6-35b-mlx | 38/38 | 100.0% | 102.5 | 1 |
| ollama | aider | gemma4-12b-mlx | 6/6 | 100.0% | 19.3 | 1 |
| mlx | pi | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 38/38 | 100.0% | 52.4 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 38/38 | 100.0% | 105.8 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 34/34 | 100.0% | 153.3 | 1 |
| mlx | copilot | /Users/jesper/src/dotfiles/link-dir/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 2/2 | 100.0% | 362.0 | 1 |
| lms | pi | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 29.5 | 1 |
| lms | pi | nvidia/nemotron-3-nano-omni | 6/6 | 100.0% | 34.3 | 1 |
| lms | pi | microsoft/phi-4 | 6/6 | 100.0% | 55.3 | 1 |
| lms | pi | google/gemma-4-e2b | 4/4 | 100.0% | 5.5 | 1 |
| lms | pi | google/gemma-4-26b-a4b-qat | 38/38 | 100.0% | 102.0 | 1 |
| lms | openhands | nvidia/nemotron-3-nano-omni | 6/6 | 100.0% | 81.7 | 1 |
| lms | opencode | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 52.4 | 1 |
| lms | opencode | qwen/qwen3-coder-next | 38/38 | 100.0% | 39.5 | 1 |
| lms | opencode | qwen/qwen3-coder-30b | 38/38 | 100.0% | 56.9 | 1 |
| lms | opencode | google/gemma-4-26b-a4b | 38/38 | 100.0% | 138.9 | 1 |
| lms | nanocoder | google/gemma-4-e4b | 6/6 | 100.0% | 30.0 | 1 |
| lms | interpreter | qwen2.5-coder-7b | 6/6 | 100.0% | 25.3 | 1 |
| lms | interpreter | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 43.1 | 1 |
| lms | interpreter | qwen/qwen3.6-27b | 38/38 | 100.0% | 126.5 | 1 |
| lms | interpreter | qwen/qwen3.5-9b | 38/38 | 100.0% | 78.1 | 1 |
| lms | interpreter | qwen/qwen3-coder-next | 38/38 | 100.0% | 31.8 | 1 |
| lms | interpreter | qwen/qwen3-coder-30b | 38/38 | 100.0% | 78.5 | 1 |
| lms | interpreter | nvidia/nemotron-3-nano-omni | 6/6 | 100.0% | 37.7 | 1 |
| lms | interpreter | microsoft/phi-4 | 2/2 | 100.0% | 53.0 | 1 |
| lms | interpreter | google/gemma-4-e4b | 6/6 | 100.0% | 91.0 | 1 |
| lms | interpreter | google/gemma-4-26b-a4b | 38/38 | 100.0% | 146.6 | 1 |
| lms | hermes | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 97.4 | 1 |
| lms | hermes | google/gemma-4-26b-a4b-qat | 38/38 | 100.0% | 83.1 | 1 |
| lms | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 | 1 |
| lms | gptme | qwen/qwen3.6-35b-a3b | 2/2 | 100.0% | 14.0 | 1 |
| lms | goose | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 51.5 | 1 |
| lms | goose | qwen/qwen3.6-27b | 38/38 | 100.0% | 459.5 | 1 |
| lms | goose | qwen/qwen3-coder-next | 38/38 | 100.0% | 112.7 | 1 |
| lms | goose | qwen/qwen3-coder-30b | 38/38 | 100.0% | 107.2 | 1 |
| lms | goose | google/gemma-4-e4b | 6/6 | 100.0% | 45.3 | 1 |
| lms | goose | google/gemma-4-26b-a4b-qat | 38/38 | 100.0% | 93.9 | 1 |
| lms | codex | qwen/qwen3.6-27b | 38/38 | 100.0% | 132.9 | 1 |
| lms | codex | qwen/qwen3-coder-next | 38/38 | 100.0% | 79.3 | 1 |
| lms | cn | qwen2.5-coder-7b | 6/6 | 100.0% | 11.0 | 1 |
| lms | cn | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 75.6 | 1 |
| lms | cn | qwen/qwen3.5-9b | 4/4 | 100.0% | 51.0 | 1 |
| lms | cline | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 53.1 | 1 |
| lms | cline | qwen/qwen3-coder-next | 38/38 | 100.0% | 52.1 | 1 |
| lms | cline | qwen/qwen3-coder-30b | 38/38 | 100.0% | 149.5 | 1 |
| lms | cline | nvidia/nemotron-3-nano-omni | 6/6 | 100.0% | 33.0 | 1 |
| lms | cline | microsoft/phi-4 | 6/6 | 100.0% | 203.7 | 1 |
| lms | cline | google/gemma-4-e2b | 4/4 | 100.0% | 14.5 | 1 |
| lms | aider | qwen/qwen3.5-9b | 38/38 | 100.0% | 47.8 | 1 |
| lms | aider | qwen/qwen3-coder-30b | 38/38 | 100.0% | 11.6 | 1 |
| lms | aider | nvidia/nemotron-3-nano-omni | 6/6 | 100.0% | 10.3 | 1 |
| lms | aider | mistralai/devstral-2-2512 | 6/6 | 100.0% | 38.3 | 1 |
| lms | aider | google/gemma-4-26b-a4b | 38/38 | 100.0% | 110.9 | 1 |
| ollama | hermes | qwen3.6-35b-mlx | 37/38 | 97.4% | 149.3 | 1 |
| lms | pi | qwen/qwen3-coder-30b | 37/38 | 97.4% | 114.3 | 1 |
| lms | opencode | google/gemma-4-26b-a4b-qat | 37/38 | 97.4% | 116.7 | 1 |
| lms | interpreter | google/gemma-4-26b-a4b-qat | 37/38 | 97.4% | 111.3 | 1 |
| lms | hermes | qwen/qwen3-coder-next | 37/38 | 97.4% | 54.9 | 1 |
| lms | hermes | google/gemma-4-26b-a4b | 37/38 | 97.4% | 128.3 | 1 |
| lms | nanocoder | qwen/qwen3.6-35b-a3b | 35/36 | 97.2% | 22.2 | 1 |
| mlx | aider | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 33/34 | 97.1% | 64.4 | 1 |
| lms | pi | qwen/qwen3-coder-next | 33/34 | 97.1% | 32.0 | 1 |
| lms | openhands | qwen/qwen3.6-35b-a3b | 33/34 | 97.1% | 61.4 | 1 |
| lms | hermes | qwen/qwen3.6-27b | 33/34 | 97.1% | 131.1 | 1 |
| lms | caveman | qwen/qwen3-coder-next | 33/34 | 97.1% | 26.1 | 1 |
| lms | caveman | google/gemma-4-12b-qat | 29/30 | 96.7% | 164.2 | 1 |
| ollama | opencode | qwen3.6:35b-mlx | 36/38 | 94.7% | 129.2 | 1 |
| ollama | cline | qwen3.6:35b-mlx | 36/38 | 94.7% | 170.8 | 1 |
| lms | nanocoder | qwen/qwen3-coder-30b | 36/38 | 94.7% | 23.6 | 1 |
| lms | nanocoder | google/gemma-4-26b-a4b-qat | 36/38 | 94.7% | 51.9 | 1 |
| lms | codex | qwen/qwen3.5-9b | 36/38 | 94.7% | 73.5 | 1 |
| lms | aider | mistralai/devstral-small-2-2512 | 36/38 | 94.7% | 32.0 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-Next-MLX-6bit | 32/34 | 94.1% | 106.8 | 1 |
| lms | cline | qwen/qwen3.5-9b | 32/34 | 94.1% | 237.4 | 1 |
| lms | opencode | google/gemma-4-12b-qat | 30/32 | 93.8% | 205.3 | 1 |
| ollama | caveman | gemma4-26b-qat | 26/28 | 92.9% | 106.1 | 1 |
| ollama | aider | gpt-oss-20b | 26/28 | 92.9% | 24.0 | 1 |
| ollama | pi | qwen3.6:35b-mlx | 35/38 | 92.1% | 95.4 | 1 |
| ollama | codex | qwen3.6-35b-mlx | 35/38 | 92.1% | 90.8 | 1 |
| lms | pi | qwen/qwen3.5-9b | 35/38 | 92.1% | 113.6 | 1 |
| lms | openhands | qwen/qwen3-coder-30b | 35/38 | 92.1% | 129.1 | 1 |
| lms | opencode | qwen/qwen3.5-9b | 35/38 | 92.1% | 69.7 | 1 |
| lms | hermes | qwen/qwen3-coder-30b | 35/38 | 92.1% | 63.5 | 1 |
| lms | codex | qwen/qwen3.6-35b-a3b | 35/38 | 92.1% | 31.5 | 1 |
| lms | codex | qwen/qwen3-coder-30b | 35/38 | 92.1% | 95.6 | 1 |
| lms | cline | google/gemma-4-26b-a4b | 35/38 | 92.1% | 181.9 | 1 |
| ollama | aider | qwen3.6:35b-mlx | 31/34 | 91.2% | 72.5 | 1 |
| ollama | hermes | gemma4-claude | 29/32 | 90.6% | 71.8 | 1 |
| lms | opencode | google/gemma-4-e2b | 29/32 | 90.6% | 34.3 | 1 |
| lms | aider | qwen2.5-coder-7b | 19/21 | 90.5% | 24.4 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 27/30 | 90.0% | 133.9 | 1 |
| ollama | hermes | qwen3.6:35b-mlx | 34/38 | 89.5% | 83.5 | 1 |
| ollama | codex | qwen3.6:35b-mlx | 34/38 | 89.5% | 45.3 | 1 |
| lms | pi | mistralai/devstral-small-2-2512 | 34/38 | 89.5% | 103.6 | 1 |
| lms | pi | google/gemma-4-26b-a4b | 34/38 | 89.5% | 169.1 | 1 |
| lms | nanocoder | qwen/qwen3.6-27b | 34/38 | 89.5% | 69.1 | 1 |
| lms | hermes | mistralai/devstral-small-2-2512 | 34/38 | 89.5% | 340.5 | 1 |
| lms | goose | qwen/qwen3.5-9b | 34/38 | 89.5% | 121.8 | 1 |
| lms | goose | mistralai/devstral-small-2-2512 | 34/38 | 89.5% | 184.1 | 1 |
| lms | cline | google/gemma-4-26b-a4b-qat | 34/38 | 89.5% | 128.2 | 1 |
| ollama | caveman | gemma4-claude | 30/34 | 88.2% | 89.8 | 1 |
| lms | opencode | google/gemma-4-e2b-qat | 28/32 | 87.5% | 44.8 | 1 |
| lms | nanocoder | mistralai/devstral-small-2-2512 | 33/38 | 86.8% | 116.3 | 1 |
| lms | hermes | qwen/qwen3.5-9b | 33/38 | 86.8% | 156.6 | 1 |
| lms | cline | mistralai/devstral-small-2-2512 | 33/38 | 86.8% | 259.5 | 1 |
| lms | aider | qwen/qwen3.6-35b-a3b | 33/38 | 86.8% | 71.3 | 1 |
| ollama | aider | gpt-oss:20b | 18/21 | 85.7% | 21.1 | 1 |
| ollama | openhands | qwen3.6:35b-mlx | 29/34 | 85.3% | 126.5 | 1 |
| lms | aider | qwen/qwen3-coder-next | 29/34 | 85.3% | 57.6 | 1 |
| lms | aider | qwen/qwen2.5-coder-7b | 29/34 | 85.3% | 13.3 | 1 |
| ollama | codex | gpt-oss-20b | 17/20 | 85.0% | 150.8 | 1 |
| lms | aider | ibm/granite-4.1-30b | 27/32 | 84.4% | 35.8 | 1 |
| ollama | openhands | gemma4:12b-mlx | 5/6 | 83.3% | 82.0 | 1 |
| lms | pi | liquid/lfm2-24b-a2b | 5/6 | 83.3% | 44.0 | 1 |
| lms | openhands | google/gemma-4-e4b | 5/6 | 83.3% | 90.7 | 1 |
| lms | openhands | google/gemma-4-26b-a4b-qat | 30/36 | 83.3% | 138.7 | 1 |
| lms | hermes | nvidia/nemotron-3-nano-omni | 5/6 | 83.3% | 54.0 | 1 |
| ollama | pi | gemma4:12b-mlx | 28/34 | 82.4% | 109.8 | 1 |
| mlx | cline | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 28/34 | 82.4% | 41.1 | 1 |
| lms | cline | qwen/qwen3.6-27b | 28/34 | 82.4% | 222.5 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 31/38 | 81.6% | 200.2 | 1 |
| lms | openhands | qwen/qwen3.5-9b | 31/38 | 81.6% | 119.6 | 1 |
| lms | aider | google/gemma-4-26b-a4b-qat | 31/38 | 81.6% | 138.9 | 1 |
| lms | caveman | google/gemma-4-e2b | 22/27 | 81.5% | 34.1 | 1 |
| lms | aider | google/gemma-4-e4b | 26/32 | 81.2% | 30.5 | 1 |
| ollama | aider | qwen3.6-35b-mlx | 29/36 | 80.6% | 118.1 | 1 |
| mlx | pi | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 27/34 | 79.4% | 59.0 | 1 |
| lms | interpreter | mistralai/devstral-small-2-2512 | 30/38 | 78.9% | 211.3 | 1 |
| lms | nanocoder | qwen/qwen2.5-coder-7b | 26/33 | 78.8% | 20.8 | 1 |
| lms | caveman | google/gemma-4-e4b-qat | 22/28 | 78.6% | 46.3 | 1 |
| lms | aider | google/gemma-4-e2b-qat | 22/28 | 78.6% | 19.7 | 1 |
| lms | aider | qwen/qwen3.6-27b | 26/34 | 76.5% | 224.5 | 1 |
| ollama | interpreter | gemma4:12b-mlx | 29/38 | 76.3% | 209.2 | 1 |
| ollama | cline | gpt-oss:20b | 16/21 | 76.2% | 38.0 | 1 |
| lms | opencode | google/gemma-4-e4b-qat | 22/29 | 75.9% | 60.2 | 1 |
| lms | caveman | ibm/granite-4.1-30b | 22/30 | 73.3% | 661.6 | 1 |
| lms | openhands | google/gemma-4-26b-a4b | 26/38 | 68.4% | 119.5 | 1 |
| ollama | hermes | gemma4:12b-mlx | 19/28 | 67.9% | 105.9 | 1 |
| ollama | aider | qwen2.5-coder:7b | 19/28 | 67.9% | 27.7 | 1 |
| ollama | opencode | gemma4:12b-mlx | 4/6 | 66.7% | 105.0 | 1 |
| ollama | cline | gemma4:12b-mlx | 4/6 | 66.7% | 82.3 | 1 |
| ollama | cline | gemma4-12b-mlx | 4/6 | 66.7% | 103.3 | 1 |
| ollama | aider | qwen2.5-coder-7b | 4/6 | 66.7% | 10.7 | 1 |
| mlx | cline | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 4/6 | 66.7% | 87.3 | 1 |
| lms | pi | qwen/qwen3.6-27b | 4/6 | 66.7% | 79.3 | 1 |
| lms | pi | google/gemma-4-e4b | 4/6 | 66.7% | 58.7 | 1 |
| lms | pi | devstral2-small | 4/6 | 66.7% | 94.7 | 1 |
| lms | opencode | qwen/qwen3.6-27b | 4/6 | 66.7% | 150.7 | 1 |
| lms | nanocoder | qwen2.5-coder-7b | 4/6 | 66.7% | 22.0 | 1 |
| lms | hermes | qwen2.5-coder-7b | 4/6 | 66.7% | 45.7 | 1 |
| lms | cn | liquid/lfm2-24b-a2b | 4/6 | 66.7% | 8.7 | 1 |
| lms | cline | liquid/lfm2-24b-a2b | 4/6 | 66.7% | 25.7 | 1 |
| lms | aider | mistralai/mistral-nemo-instruct-2407 | 4/6 | 66.7% | 9.0 | 1 |
| lms | opencode | google/gemma-4-e4b | 25/38 | 65.8% | 67.7 | 1 |
| lms | codex | zai-org/glm-4.7-flash | 25/38 | 65.8% | 271.7 | 1 |
| lms | codex | google/gemma-4-26b-a4b-qat | 23/35 | 65.7% | 203.8 | 1 |
| ollama | opencode | gpt-oss-20b | 21/32 | 65.6% | 42.8 | 1 |
| lms | aider | google/gemma-4-e2b | 17/26 | 65.4% | 18.9 | 1 |
| lms | aider | google/gemma-4-e4b-qat | 18/28 | 64.3% | 21.4 | 1 |
| lms | pi | qwen2.5-coder-7b | 13/21 | 61.9% | 38.0 | 1 |
| lms | hermes | qwen/qwen2.5-coder-7b | 22/36 | 61.1% | 50.3 | 1 |
| lms | codex | ibm/granite-4.1-30b | 16/27 | 59.3% | 342.6 | 1 |
| lms | interpreter | qwen/qwen2.5-coder-7b | 17/29 | 58.6% | 49.8 | 1 |
| lms | codex | google/gemma-4-e4b-qat | 14/24 | 58.3% | 128.6 | 1 |
| lms | caveman | google/gemma-4-e4b | 22/38 | 57.9% | 45.7 | 1 |
| ollama | aider | gemma4:12b-mlx | 18/32 | 56.2% | 95.2 | 1 |
| mlx | aider | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 18/32 | 56.2% | 17.6 | 1 |
| lms | copilot | google/gemma-4-26b-a4b-qat | 18/32 | 56.2% | 79.9 | 1 |
| lms | codex | google/gemma-4-12b-qat | 19/34 | 55.9% | 216.1 | 1 |
| ollama | aider | gemma4-26b-qat | 15/28 | 53.6% | 166.4 | 1 |
| lms | caveman | google/gemma-4-e2b-qat | 15/28 | 53.6% | 21.9 | 1 |
| lms | codex | qwen2.5-coder-7b | 11/21 | 52.4% | 48.3 | 1 |
| lms | codex | mistralai/devstral-small-2-2512 | 11/21 | 52.4% | 213.9 | 1 |
| lms | cline | qwen2.5-coder-7b | 11/21 | 52.4% | 75.6 | 1 |
| lms | cline | qwen/qwen2.5-coder-7b | 15/29 | 51.7% | 56.0 | 1 |
| ollama | codex | gemma4:12b-mlx | 3/6 | 50.0% | 127.0 | 1 |
| lms | openhands | qwen2.5-coder-7b | 3/6 | 50.0% | 79.3 | 1 |
| lms | nanocoder | qwen/qwen3.5-9b | 16/32 | 50.0% | 15.8 | 1 |
| lms | interpreter | google/gemma-4-e2b | 2/4 | 50.0% | 17.0 | 1 |
| lms | goose | mistralai/mistral-nemo-instruct-2407 | 3/6 | 50.0% | 17.7 | 1 |
| lms | cline | google/gemma-4-e4b | 3/6 | 50.0% | 56.0 | 1 |
| lms | aider | microsoft/phi-4 | 3/6 | 50.0% | 32.3 | 1 |
| lms | goose | qwen/qwen2.5-coder-7b | 15/32 | 46.9% | 13.0 | 1 |
| lms | opencode | ibm/granite-4.1-30b | 13/28 | 46.4% | 279.8 | 1 |
| lms | interpreter | zai-org/glm-4.7-flash | 14/32 | 43.8% | 203.1 | 1 |
| lms | copilot | qwen/qwen3.6-35b-a3b | 14/32 | 43.8% | 32.1 | 1 |
| lms | codex | google/gemma-4-e2b-qat | 12/28 | 42.9% | 50.7 | 1 |
| lms | aider | google/gemma-4-12b-qat | 11/28 | 39.3% | 102.7 | 1 |
| lms | codex | google/gemma-4-e4b | 13/34 | 38.2% | 81.5 | 1 |
| lms | codex | google/gemma-4-e2b | 13/34 | 38.2% | 36.0 | 1 |
| ollama | pi | qwen3.6-35b-mlx | 12/32 | 37.5% | 1.7 | 1 |
| ollama | opencode | qwen3.6-35b-mlx | 12/32 | 37.5% | 3.2 | 1 |
| ollama | cline | qwen3.6-35b-mlx | 12/32 | 37.5% | 5.1 | 1 |
| ollama | caveman | qwen3.6:35b-mlx | 12/32 | 37.5% | 1.4 | 1 |
| mlx | opencode | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 12/32 | 37.5% | 2.0 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 12/32 | 37.5% | 75.9 | 1 |
| mlx | codex | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 12/32 | 37.5% | 2.0 | 1 |
| mlx | caveman | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 12/32 | 37.5% | 2.0 | 1 |
| lms | pi | zai-org/glm-4.7-flash | 12/32 | 37.5% | 132.7 | 1 |
| lms | openhands | zai-org/glm-4.7-flash | 12/32 | 37.5% | 122.4 | 1 |
| lms | openhands | mistralai/devstral-small-2-2512 | 12/32 | 37.5% | 122.2 | 1 |
| lms | opencode | zai-org/glm-4.7-flash | 12/32 | 37.5% | 2.1 | 1 |
| lms | opencode | mistralai/devstral-small-2-2512 | 12/32 | 37.5% | 2.3 | 1 |
| lms | nanocoder | zai-org/glm-4.7-flash | 12/32 | 37.5% | 300.6 | 1 |
| lms | hermes | zai-org/glm-4.7-flash | 12/32 | 37.5% | 180.7 | 1 |
| lms | goose | zai-org/glm-4.7-flash | 12/32 | 37.5% | 141.1 | 1 |
| lms | copilot | zai-org/glm-4.7-flash | 12/32 | 37.5% | 300.8 | 1 |
| lms | copilot | qwen/qwen3.5-9b | 12/32 | 37.5% | 181.4 | 1 |
| lms | copilot | qwen/qwen3-coder-30b | 12/32 | 37.5% | 34.5 | 1 |
| lms | copilot | mistralai/devstral-small-2-2512 | 12/32 | 37.5% | 187.4 | 1 |
| lms | codex | google/gemma-4-26b-a4b | 12/32 | 37.5% | 2.1 | 1 |
| lms | cline | zai-org/glm-4.7-flash | 12/32 | 37.5% | 18.3 | 1 |
| lms | caveman | zai-org/glm-4.7-flash | 12/32 | 37.5% | 2.0 | 1 |
| lms | caveman | qwen/qwen3.6-35b-a3b | 12/32 | 37.5% | 2.0 | 1 |
| lms | caveman | qwen/qwen3.5-9b | 12/32 | 37.5% | 2.0 | 1 |
| lms | caveman | qwen/qwen3-coder-30b | 12/32 | 37.5% | 2.0 | 1 |
| lms | caveman | mistralai/devstral-small-2-2512 | 12/32 | 37.5% | 2.1 | 1 |
| lms | caveman | google/gemma-4-26b-a4b-qat | 12/32 | 37.5% | 2.1 | 1 |
| lms | caveman | google/gemma-4-26b-a4b | 12/32 | 37.5% | 2.0 | 1 |
| lms | aider | zai-org/glm-4.7-flash | 12/32 | 37.5% | 454.6 | 1 |
| ollama | pi | gemma4-12b-mlx | 2/6 | 33.3% | 73.3 | 1 |
| ollama | openhands | gemma4-12b-mlx | 2/6 | 33.3% | 111.0 | 1 |
| ollama | copilot | qwen3.6:35b-mlx | 2/6 | 33.3% | 29.0 | 1 |
| ollama | copilot | gemma4:12b-mlx | 2/6 | 33.3% | 98.0 | 1 |
| ollama | copilot | gemma4-12b-mlx | 2/6 | 33.3% | 113.0 | 1 |
| mlx | opencode | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 2/6 | 33.3% | 235.0 | 1 |
| lms | nanocoder | liquid/lfm2-24b-a2b | 2/6 | 33.3% | 72.0 | 1 |
| lms | hermes | liquid/lfm2-24b-a2b | 2/6 | 33.3% | 21.7 | 1 |
| lms | goose | qwen2.5-coder-7b | 7/21 | 33.3% | 43.7 | 1 |
| lms | goose | liquid/lfm2-24b-a2b | 2/6 | 33.3% | 19.7 | 1 |
| lms | copilot | nvidia/nemotron-3-nano-omni | 2/6 | 33.3% | 62.3 | 1 |
| lms | copilot | google/gemma-4-e4b | 2/6 | 33.3% | 54.3 | 1 |
| lms | codex | nvidia/nemotron-3-nano-omni | 2/6 | 33.3% | 18.0 | 1 |
| lms | aider | liquid/lfm2-24b-a2b | 2/6 | 33.3% | 20.3 | 1 |
| lms | hermes | google/gemma-4-e2b-qat | 9/28 | 32.1% | 15.3 | 1 |
| ollama | hermes | qwen3.5-claude | 8/26 | 30.8% | 141.4 | 1 |
| lms | copilot | ibm/granite-4.1-30b | 9/30 | 30.0% | 291.9 | 1 |
| ollama | caveman | qwen3.5-claude | 6/22 | 27.3% | 122.4 | 1 |
| lms | hermes | google/gemma-4-e4b | 8/32 | 25.0% | 11.1 | 1 |
| lms | opencode | qwen2.5-coder-7b | 5/21 | 23.8% | 70.1 | 1 |
| lms | copilot | qwen2.5-coder-7b | 5/21 | 23.8% | 66.0 | 1 |
| lms | claude | qwen/qwen3.6-35b-a3b | 5/21 | 23.8% | 2.1 | 1 |
| lms | aider | microsoft/phi-4-mini | 7/30 | 23.3% | 30.9 | 1 |
| lms | codex | microsoft/phi-4-mini | 7/32 | 21.9% | 394.6 | 1 |
| ollama | hermes | qwen3.5:9b | 1/5 | 20.0% | 190.5 | 1 |
| lms | opencode | microsoft/phi-4-mini | 6/30 | 20.0% | 5.8 | 1 |
| lms | hermes | microsoft/phi-4-mini | 6/30 | 20.0% | 96.6 | 1 |
| lms | hermes | google/gemma-4-e2b | 6/30 | 20.0% | 5.4 | 1 |
| lms | caveman | microsoft/phi-4-mini | 6/30 | 20.0% | 133.6 | 1 |
| mlx | hermes | mlx-community/Phi-4-4bit | 2/12 | 16.7% | 28.0 | 3 |
| lms | opencode | liquid/lfm2-24b-a2b | 1/6 | 16.7% | 41.0 | 1 |
| ollama | opencode | qwen2.5-coder:7b | 2/28 | 7.1% | 0.9 | 1 |
| ollama | opencode | phi4:latest | 2/28 | 7.1% | 0.9 | 1 |
| ollama | opencode | phi4-mini:latest | 2/28 | 7.1% | 1.0 | 1 |
| mlx | hermes | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 107.3 | 3 |
| mlx | codex | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 0.0 | 3 |
| mlx | codex | mlx-community/Phi-4-4bit | 2/28 | 7.1% | 0.0 | 3 |
| mlx | caveman | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 0.9 | 3 |
| mlx | caveman | mlx-community/Phi-4-4bit | 2/28 | 7.1% | 0.0 | 3 |
| lms | hermes | ibm/granite-4.1-30b | 2/28 | 7.1% | 252.2 | 1 |
| lms | hermes | google/gemma-4-e4b-qat | 2/28 | 7.1% | 3.6 | 1 |
| lms | hermes | google/gemma-4-12b-qat | 2/28 | 7.1% | 3.7 | 1 |
| lms | copilot | microsoft/phi-4-mini | 2/28 | 7.1% | 56.2 | 1 |
| ollama | pi | qwen2.5-coder-7b | 0/6 | 0.0% | 18.3 | 1 |
| ollama | openhands | qwen2.5-coder-7b | 0/6 | 0.0% | 46.3 | 1 |
| ollama | opencode | qwen2.5-coder-7b | 0/6 | 0.0% | 2.0 | 1 |
| ollama | interpreter | qwen2.5-coder-7b | 0/6 | 0.0% | 11.3 | 1 |
| ollama | hermes | qwen2.5-coder-7b | 0/6 | 0.0% | 12.3 | 1 |
| ollama | copilot | qwen2.5-coder-7b | 0/6 | 0.0% | 39.0 | 1 |
| ollama | codex | qwen2.5-coder-7b | 0/6 | 0.0% | 2.0 | 1 |
| ollama | codex | gemma4-12b-mlx | 0/6 | 0.0% | 92.7 | 1 |
| ollama | cline | qwen2.5-coder-7b | 0/6 | 0.0% | 12.7 | 1 |
| ollama | caveman | qwen2.5-coder-7b | 0/6 | 0.0% | 2.0 | 1 |
| ollama | caveman | phi4-mini:latest | 0/2 | 0.0% | 1.0 | 1 |
| ollama | caveman | gemma4:12b-mlx | 0/6 | 0.0% | 2.0 | 1 |
| ollama | caveman | gemma4-12b-mlx | 0/6 | 0.0% | 2.0 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/gemma-4-E2B-it-MLX-4bit | 0/2 | 0.0% | 121.0 | 1 |
| mlx | codex | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 0/6 | 0.0% | 0.3 | 1 |
| mlx | caveman | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 0/6 | 0.0% | 0.7 | 1 |
| lms | pi | mistralai/mistral-nemo-instruct-2407 | 0/6 | 0.0% | 26.0 | 1 |
| lms | pi | mistralai/mistral-7b-instruct-v0.3 | 0/6 | 0.0% | 2.7 | 1 |
| lms | pi | mistralai/devstral-2-2512 | 0/6 | 0.0% | 2.0 | 1 |
| lms | openhands | qwen/qwen3.6-27b | 0/6 | 0.0% | 123.3 | 1 |
| lms | openhands | mistralai/devstral-2-2512 | 0/6 | 0.0% | 8.3 | 1 |
| lms | openhands | liquid/lfm2-24b-a2b | 0/6 | 0.0% | 52.3 | 1 |
| lms | opencode | nvidia/nemotron-3-nano-omni | 0/6 | 0.0% | 2.0 | 1 |
| lms | opencode | mistralai/mistral-nemo-instruct-2407 | 0/6 | 0.0% | 2.3 | 1 |
| lms | opencode | mistralai/devstral-2-2512 | 0/6 | 0.0% | 2.0 | 1 |
| lms | opencode | microsoft/phi-4 | 0/6 | 0.0% | 2.0 | 1 |
| lms | nanocoder | mistralai/mistral-nemo-instruct-2407 | 0/6 | 0.0% | 27.3 | 1 |
| lms | mini-swe-agent | qwen/qwen3.6-35b-a3b | 0/2 | 0.0% | 181.0 | 1 |
| lms | interpreter | mistralai/mistral-nemo-instruct-2407 | 0/6 | 0.0% | 29.3 | 1 |
| lms | interpreter | mistralai/devstral-2-2512 | 0/6 | 0.0% | 2.0 | 1 |
| lms | interpreter | liquid/lfm2-24b-a2b | 0/6 | 0.0% | 35.3 | 1 |
| lms | hermes | mistralai/mistral-nemo-instruct-2407 | 0/6 | 0.0% | 26.0 | 1 |
| lms | hermes | mistralai/mistral-7b-instruct-v0.3 | 0/6 | 0.0% | 19.0 | 1 |
| lms | hermes | mistralai/devstral-2-2512 | 0/6 | 0.0% | 5.3 | 1 |
| lms | goose | nvidia/nemotron-3-nano-omni | 0/6 | 0.0% | 2.0 | 1 |
| lms | goose | mistralai/devstral-2-2512 | 0/6 | 0.0% | 8.7 | 1 |
| lms | copilot | qwen/qwen3.6-27b | 0/6 | 0.0% | 86.7 | 1 |
| lms | copilot | mistralai/devstral-2-2512 | 0/6 | 0.0% | 2.0 | 1 |
| lms | copilot | liquid/lfm2-24b-a2b | 0/6 | 0.0% | 47.7 | 1 |
| lms | codex | mistralai/devstral-2-2512 | 0/6 | 0.0% | 2.0 | 1 |
| lms | codex | liquid/lfm2-24b-a2b | 0/6 | 0.0% | 55.3 | 1 |
| lms | cline | mistralai/mistral-nemo-instruct-2407 | 0/6 | 0.0% | 29.3 | 1 |
| lms | cline | mistralai/mistral-7b-instruct-v0.3 | 0/6 | 0.0% | 4.0 | 1 |
| lms | cline | mistralai/devstral-2-2512 | 0/6 | 0.0% | 100.3 | 1 |
| lms | caveman | qwen2.5-coder-7b | 0/6 | 0.0% | 2.3 | 1 |
| lms | caveman | qwen/qwen3.6-27b | 0/6 | 0.0% | 2.0 | 1 |
| lms | caveman | nvidia/nemotron-3-nano-omni | 0/6 | 0.0% | 2.0 | 1 |
| lms | caveman | mistralai/devstral-2-2512 | 0/6 | 0.0% | 2.3 | 1 |
| lms | caveman | liquid/lfm2-24b-a2b | 0/6 | 0.0% | 2.0 | 1 |
| lms | aider | mistralai/mistral-7b-instruct-v0.3 | 0/6 | 0.0% | 79.0 | 1 |

## Leaderboard — by model

| Runtime | Model | Pass | Pass% | Avg s |
|---------|-------|------|-------|-------|
| ollama | qwen3.6:35b-a3b-coding-mxfp8 | 8/8 | 100.0% | 70.2 |
| mlx | /Users/jesper/src/dotfiles/link-dir/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 2/2 | 100.0% | 362.0 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 34/34 | 100.0% | 153.3 |
| lms | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 |
| lms | qwen/qwen3-coder-next | 322/330 | 97.6% | 54.0 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-Next-MLX-6bit | 32/34 | 94.1% | 106.8 |
| ollama | gemma4-claude | 59/66 | 89.4% | 80.8 |
| lms | qwen/qwen3-coder-30b | 392/444 | 88.3% | 72.2 |
| lms | qwen/qwen3.6-35b-a3b | 435/501 | 86.8% | 46.5 |
| ollama | qwen3.6:35b-mlx | 287/334 | 85.9% | 86.9 |
| lms | qwen/qwen3.6-27b | 243/284 | 85.6% | 177.8 |
| lms | google/gemma-4-26b-a4b-qat | 372/439 | 84.7% | 104.2 |
| ollama | gemma4-26b-qat | 75/90 | 83.3% | 132.7 |
| lms | google/gemma-4-26b-a4b | 270/330 | 81.8% | 111.0 |
| lms | qwen/qwen3.5-9b | 356/438 | 81.3% | 101.1 |
| ollama | gpt-oss:20b | 34/42 | 81.0% | 29.6 |
| ollama | gpt-oss-20b | 64/80 | 80.0% | 58.9 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 124/160 | 77.5% | 106.2 |
| ollama | qwen3.6-35b-mlx | 175/246 | 71.1% | 67.2 |
| lms | mistralai/devstral-small-2-2512 | 293/415 | 70.6% | 145.9 |
| ollama | gemma4:12b-mlx | 112/168 | 66.7% | 116.3 |
| lms | devstral2-small | 4/6 | 66.7% | 94.7 |
| lms | microsoft/phi-4 | 17/26 | 65.4% | 71.8 |
| lms | qwen/qwen2.5-coder-7b | 124/193 | 64.2% | 33.9 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.6-35B-A3B-MLX-4bit | 170/270 | 63.0% | 37.4 |
| lms | google/gemma-4-e2b | 97/161 | 60.2% | 24.3 |
| lms | google/gemma-4-12b-qat | 91/152 | 59.9% | 138.4 |
| lms | google/gemma-4-e2b-qat | 86/144 | 59.7% | 30.5 |
| lms | nvidia/nemotron-3-nano-omni | 39/66 | 59.1% | 30.7 |
| lms | google/gemma-4-e4b | 126/216 | 58.3% | 51.0 |
| lms | google/gemma-4-e4b-qat | 78/137 | 56.9% | 52.0 |
| ollama | gemma4-12b-mlx | 34/60 | 56.7% | 74.6 |
| lms | qwen2.5-coder-7b | 94/183 | 51.4% | 46.6 |
| lms | ibm/granite-4.1-30b | 89/175 | 50.9% | 310.6 |
| lms | zai-org/glm-4.7-flash | 159/390 | 40.8% | 177.5 |
| ollama | qwen2.5-coder:7b | 21/56 | 37.5% | 14.3 |
| ollama | qwen3.5-claude | 14/48 | 29.2% | 131.9 |
| lms | liquid/lfm2-24b-a2b | 22/78 | 28.2% | 34.3 |
| ollama | qwen3.5:9b | 1/5 | 20.0% | 190.5 |
| lms | microsoft/phi-4-mini | 34/180 | 18.9% | 120.7 |
| lms | mistralai/mistral-nemo-instruct-2407 | 7/48 | 14.6% | 20.9 |
| lms | mistralai/devstral-2-2512 | 6/66 | 9.1% | 15.8 |
| mlx | mlx-community/Phi-4-4bit | 6/68 | 8.8% | 4.0 |
| ollama | phi4:latest | 2/28 | 7.1% | 0.9 |
| mlx | mlx-community/Phi-4-mini-instruct-4bit | 6/84 | 7.1% | 36.1 |
| ollama | qwen2.5-coder-7b | 4/60 | 6.7% | 15.7 |
| ollama | phi4-mini:latest | 2/30 | 6.7% | 1.0 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/gemma-4-E2B-it-MLX-4bit | 0/2 | 0.0% | 121.0 |
| lms | mistralai/mistral-7b-instruct-v0.3 | 0/24 | 0.0% | 26.2 |

## Leaderboard — by adapter

| Adapter | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| gptme | 2/2 | 100.0% | 14.0 |
| cn | 52/54 | 96.3% | 52.3 |
| interpreter | 421/495 | 85.1% | 100.5 |
| pi | 455/567 | 80.2% | 75.8 |
| goose | 303/381 | 79.5% | 121.7 |
| nanocoder | 240/309 | 77.7% | 72.8 |
| cline | 441/573 | 77.0% | 106.1 |
| aider | 695/908 | 76.5% | 74.8 |
| openhands | 229/336 | 68.2% | 107.5 |
| hermes | 640/971 | 65.9% | 102.2 |
| opencode | 544/846 | 64.3% | 63.5 |
| codex | 465/776 | 59.9% | 108.3 |
| caveman | 385/769 | 50.1% | 56.5 |
| copilot | 179/425 | 42.1% | 118.5 |
| claude | 5/21 | 23.8% | 2.1 |
| mini-swe-agent | 0/2 | 0.0% | 181.0 |
