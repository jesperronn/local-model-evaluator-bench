# Benchmark Report

**Source:** `all runs (latest per adapter+model+case)`
**Generated:** 2026-06-19 08:12

## Models to Avoid

The following models have **broken or unusable tool calling** in our local setup and should not be used for agentic coding work. They score ≤20% overall — the 7.1% entries pass only the initial smoke test (2/28), meaning zero real tool calls succeed. The ≤20% models have sparse successes but no adapter where they are reliably useful.

**Threshold:** ≤20% pass rate across ≥28 trials.

| Runtime | Model | Pass% | Pattern | Avoid reason |
|---------|-------|-------|---------|--------------|
| lms | `microsoft/phi-4-mini` | 18.9% | sparse passes; 7/30 typical | Tool calls rarely complete correctly |
| lms | `google/gemma-4-12b` | 13.6% | mostly infra failures + capability gap | Tool calling broken; infra failures contaminated results |
| mlx | `mlx-community/Phi-4-4bit` | 8.8% | 2/28 on most adapters | Smoke test only; no real tool calls succeed |
| ollama | `phi4:latest` | 7.1% | 2/28 | Smoke test only; no real tool calls succeed |
| mlx | `mlx-community/Phi-4-mini-instruct-4bit` | 7.1% | 2/28 | Smoke test only; no real tool calls succeed |
| lms | `google/gemma-4-31b-qat` | 7.1% | 2/28 on all adapters | Smoke test only; likely non-instruct or misconfigured variant |
| lms | `google/gemma-4-31b` | 7.1% | 2/28 on all adapters | Smoke test only; likely non-instruct or misconfigured variant |
| ollama | `phi4-mini:latest` | 6.7% | 2/30 | Smoke test only; no real tool calls succeed |
| mlx | `gemma-4-E2B-it-MLX-4bit` | 0.0% | 0/2 | Complete failure |

**The 7.1% pattern explained:** a score of 2/28 means the model passed the smoke test sub-cases (`js-01-slugify-bug` first two checks) which require only basic text output, but scored zero on every actual tool-use case. These models are connected and responding but cannot correctly execute file-editing tool calls.

**Phi-4 family:** All three runtimes (lms, Ollama, MLX) show broken tool calling for both Phi-4 and Phi-4 mini. This is a consistent model-family issue, not a runtime-specific one. See individual model cards for details.

**Cleanup planned:** these models are candidates for removal from `models-ollama.txt`, `models.txt`, and the LM Studio model library. See individual model cards for per-model recommendations.

---

## Leaderboard — by runtime

| Runtime | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| ollama | 415/651 | 63.7% | 72.1 |
| lms | 1841/2933 | 62.8% | 104.7 |
| mlx | 135/290 | 46.6% | 80.3 |

## Leaderboard — by adapter × model

| Runtime | Adapter | Model | Pass | Pass% | Avg s | Trials |
|---------|---------|-------|------|-------|-------|--------|
| ollama | opencode | gemma4-26b-qat | 34/34 | 100.0% | 125.4 | 1 |
| ollama | caveman | qwen3.6:35b-a3b-coding-mxfp8 | 2/2 | 100.0% | 38.0 | 1 |
| ollama | caveman | qwen3.6-35b-mlx | 38/38 | 100.0% | 102.5 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 34/34 | 100.0% | 153.3 | 1 |
| mlx | copilot | /Users/jesper/src/dotfiles/link-dir/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 2/2 | 100.0% | 362.0 | 1 |
| lms | pi | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 40.3 | 1 |
| lms | pi | qwen/qwen3-coder-next | 4/4 | 100.0% | 17.0 | 1 |
| lms | pi | qwen/qwen3-coder-30b | 4/4 | 100.0% | 10.5 | 1 |
| lms | pi | google/gemma-4-e2b | 4/4 | 100.0% | 5.5 | 1 |
| lms | pi | google/gemma-4-26b-a4b-qat | 38/38 | 100.0% | 161.7 | 1 |
| lms | interpreter | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 67.7 | 1 |
| lms | interpreter | qwen/qwen3.5-9b | 38/38 | 100.0% | 105.7 | 1 |
| lms | interpreter | qwen/qwen3-coder-next | 4/4 | 100.0% | 19.0 | 1 |
| lms | interpreter | qwen/qwen3-coder-30b | 4/4 | 100.0% | 11.0 | 1 |
| lms | interpreter | google/gemma-4-26b-a4b-qat | 4/4 | 100.0% | 15.0 | 1 |
| lms | hermes | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 87.4 | 1 |
| lms | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 | 1 |
| lms | goose | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 96.2 | 1 |
| lms | goose | qwen/qwen3-coder-next | 4/4 | 100.0% | 54.5 | 1 |
| lms | goose | qwen/qwen3-coder-30b | 4/4 | 100.0% | 11.5 | 1 |
| lms | goose | google/gemma-4-26b-a4b-qat | 4/4 | 100.0% | 25.0 | 1 |
| lms | copilot | qwen/qwen3.6-35b-a3b | 34/34 | 100.0% | 77.6 | 1 |
| lms | codex | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 82.8 | 1 |
| lms | codex | qwen/qwen3.5-9b | 38/38 | 100.0% | 99.4 | 1 |
| lms | codex | qwen/qwen3-coder-next | 36/36 | 100.0% | 77.7 | 1 |
| lms | codex | qwen/qwen3-coder-30b | 36/36 | 100.0% | 76.8 | 1 |
| lms | codex | google/gemma-4-26b-a4b-qat | 36/36 | 100.0% | 118.4 | 1 |
| lms | cline | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 86.7 | 1 |
| lms | cline | qwen/qwen3-coder-next | 4/4 | 100.0% | 18.0 | 1 |
| lms | cline | qwen/qwen3-coder-30b | 4/4 | 100.0% | 43.0 | 1 |
| lms | cline | google/gemma-4-e2b | 4/4 | 100.0% | 14.5 | 1 |
| lms | cline | google/gemma-4-26b-a4b-qat | 4/4 | 100.0% | 26.5 | 1 |
| lms | caveman | qwen/qwen3.6-35b-a3b | 38/38 | 100.0% | 66.1 | 1 |
| lms | caveman | qwen/qwen3-coder-30b | 36/36 | 100.0% | 51.6 | 1 |
| lms | caveman | google/gemma-4-26b-a4b-qat | 36/36 | 100.0% | 76.2 | 1 |
| lms | aider | qwen/qwen3.5-9b | 38/38 | 100.0% | 61.1 | 1 |
| ollama | hermes | qwen3.6-35b-mlx | 37/38 | 97.4% | 149.3 | 1 |
| lms | opencode | qwen/qwen3.5-9b | 37/38 | 97.4% | 137.8 | 1 |
| lms | aider | qwen/qwen3.6-35b-a3b | 37/38 | 97.4% | 56.3 | 1 |
| lms | opencode | qwen/qwen3-coder-30b | 35/36 | 97.2% | 59.9 | 1 |
| lms | caveman | qwen/qwen3-coder-next | 31/32 | 96.9% | 28.3 | 1 |
| lms | caveman | google/gemma-4-12b-qat | 29/30 | 96.7% | 164.2 | 1 |
| lms | opencode | qwen/qwen3.6-35b-a3b | 36/38 | 94.7% | 69.2 | 1 |
| lms | hermes | qwen/qwen3.5-9b | 36/38 | 94.7% | 495.3 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-Next-MLX-6bit | 32/34 | 94.1% | 106.8 | 1 |
| lms | opencode | google/gemma-4-12b-qat | 30/32 | 93.8% | 205.3 | 1 |
| ollama | caveman | gemma4-26b-qat | 26/28 | 92.9% | 106.1 | 1 |
| ollama | aider | gpt-oss-20b | 26/28 | 92.9% | 24.0 | 1 |
| ollama | codex | qwen3.6-35b-mlx | 35/38 | 92.1% | 90.8 | 1 |
| lms | pi | qwen/qwen3.5-9b | 35/38 | 92.1% | 96.0 | 1 |
| lms | opencode | google/gemma-4-26b-a4b-qat | 33/36 | 91.7% | 99.6 | 1 |
| ollama | hermes | gemma4-claude | 29/32 | 90.6% | 71.8 | 1 |
| lms | opencode | google/gemma-4-e2b | 29/32 | 90.6% | 34.3 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 27/30 | 90.0% | 133.9 | 1 |
| ollama | caveman | gemma4-claude | 30/34 | 88.2% | 89.8 | 1 |
| lms | opencode | google/gemma-4-e2b-qat | 28/32 | 87.5% | 44.8 | 1 |
| ollama | codex | gpt-oss-20b | 17/20 | 85.0% | 150.8 | 1 |
| lms | aider | ibm/granite-4.1-30b | 27/32 | 84.4% | 35.8 | 1 |
| lms | copilot | google/gemma-4-26b-a4b-qat | 25/30 | 83.3% | 190.4 | 1 |
| mlx | hermes | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 28/34 | 82.4% | 210.8 | 1 |
| lms | aider | qwen/qwen3-coder-30b | 28/34 | 82.4% | 9.4 | 1 |
| lms | caveman | qwen/qwen3.5-9b | 31/38 | 81.6% | 52.3 | 1 |
| lms | caveman | google/gemma-4-e2b | 22/27 | 81.5% | 34.1 | 1 |
| ollama | aider | qwen3.6-35b-mlx | 29/36 | 80.6% | 118.1 | 1 |
| lms | hermes | google/gemma-4-26b-a4b-qat | 29/36 | 80.6% | 163.6 | 1 |
| lms | caveman | google/gemma-4-e4b-qat | 22/28 | 78.6% | 46.3 | 1 |
| lms | aider | google/gemma-4-e4b | 22/28 | 78.6% | 33.6 | 1 |
| lms | aider | google/gemma-4-e2b-qat | 22/28 | 78.6% | 19.7 | 1 |
| lms | opencode | google/gemma-4-e4b-qat | 22/29 | 75.9% | 60.2 | 1 |
| lms | cline | qwen/qwen3.5-9b | 28/38 | 73.7% | 1540.9 | 1 |
| lms | opencode | google/gemma-4-e4b | 25/34 | 73.5% | 73.8 | 1 |
| lms | aider | qwen/qwen3-coder-next | 25/34 | 73.5% | 16.0 | 1 |
| lms | caveman | ibm/granite-4.1-30b | 22/30 | 73.3% | 661.6 | 1 |
| lms | goose | qwen/qwen3.5-9b | 23/32 | 71.9% | 51.3 | 1 |
| lms | caveman | google/gemma-4-e4b | 24/34 | 70.6% | 56.6 | 1 |
| ollama | aider | qwen2.5-coder:7b | 19/28 | 67.9% | 27.7 | 1 |
| ollama | opencode | gpt-oss-20b | 21/32 | 65.6% | 42.8 | 1 |
| lms | aider | google/gemma-4-26b-a4b-qat | 21/32 | 65.6% | 163.9 | 1 |
| lms | aider | google/gemma-4-e2b | 17/26 | 65.4% | 18.9 | 1 |
| lms | aider | google/gemma-4-e4b-qat | 18/28 | 64.3% | 21.4 | 1 |
| lms | codex | ibm/granite-4.1-30b | 16/27 | 59.3% | 342.6 | 1 |
| lms | codex | google/gemma-4-e4b-qat | 14/24 | 58.3% | 128.6 | 1 |
| lms | codex | google/gemma-4-12b-qat | 19/34 | 55.9% | 216.1 | 1 |
| ollama | aider | gemma4-26b-qat | 15/28 | 53.6% | 166.4 | 1 |
| lms | caveman | google/gemma-4-e2b-qat | 15/28 | 53.6% | 21.9 | 1 |
| lms | interpreter | google/gemma-4-e2b | 2/4 | 50.0% | 17.0 | 1 |
| lms | copilot | qwen/qwen3.5-9b | 17/34 | 50.0% | 29.9 | 1 |
| lms | codex | google/gemma-4-e4b | 15/30 | 50.0% | 100.0 | 1 |
| lms | aider | qwen/qwen3.6-27b | 4/8 | 50.0% | 269.5 | 1 |
| lms | opencode | ibm/granite-4.1-30b | 13/28 | 46.4% | 279.8 | 1 |
| lms | codex | google/gemma-4-e2b-qat | 12/28 | 42.9% | 50.7 | 1 |
| lms | aider | google/gemma-4-12b-qat | 11/28 | 39.3% | 102.7 | 1 |
| lms | aider | google/gemma-4-12b | 11/28 | 39.3% | 115.6 | 1 |
| lms | codex | google/gemma-4-e2b | 13/34 | 38.2% | 36.0 | 1 |
| ollama | pi | qwen3.6-35b-mlx | 12/32 | 37.5% | 1.7 | 1 |
| ollama | opencode | qwen3.6-35b-mlx | 12/32 | 37.5% | 3.2 | 1 |
| ollama | cline | qwen3.6-35b-mlx | 12/32 | 37.5% | 5.1 | 1 |
| lms | hermes | google/gemma-4-e2b-qat | 9/28 | 32.1% | 15.3 | 1 |
| ollama | hermes | qwen3.5-claude | 8/26 | 30.8% | 141.4 | 1 |
| lms | copilot | ibm/granite-4.1-30b | 9/30 | 30.0% | 291.9 | 1 |
| ollama | caveman | qwen3.5-claude | 6/22 | 27.3% | 122.4 | 1 |
| lms | aider | microsoft/phi-4-mini | 7/30 | 23.3% | 30.9 | 1 |
| lms | codex | microsoft/phi-4-mini | 7/32 | 21.9% | 394.6 | 1 |
| ollama | hermes | qwen3.5:9b | 1/5 | 20.0% | 190.5 | 1 |
| lms | opencode | qwen/qwen3-coder-next | 6/30 | 20.0% | 5.6 | 1 |
| lms | opencode | microsoft/phi-4-mini | 6/30 | 20.0% | 5.8 | 1 |
| lms | hermes | qwen/qwen3-coder-next | 6/30 | 20.0% | 6.4 | 1 |
| lms | hermes | qwen/qwen3-coder-30b | 6/30 | 20.0% | 322.8 | 1 |
| lms | hermes | microsoft/phi-4-mini | 6/30 | 20.0% | 96.6 | 1 |
| lms | hermes | google/gemma-4-e2b | 6/30 | 20.0% | 5.4 | 1 |
| lms | caveman | microsoft/phi-4-mini | 6/30 | 20.0% | 133.6 | 1 |
| mlx | hermes | mlx-community/Phi-4-4bit | 2/12 | 16.7% | 28.0 | 3 |
| ollama | opencode | qwen2.5-coder:7b | 2/28 | 7.1% | 0.9 | 1 |
| ollama | opencode | phi4:latest | 2/28 | 7.1% | 0.9 | 1 |
| ollama | opencode | phi4-mini:latest | 2/28 | 7.1% | 1.0 | 1 |
| mlx | hermes | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 107.3 | 3 |
| mlx | codex | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 0.0 | 3 |
| mlx | codex | mlx-community/Phi-4-4bit | 2/28 | 7.1% | 0.0 | 3 |
| mlx | caveman | mlx-community/Phi-4-mini-instruct-4bit | 2/28 | 7.1% | 0.9 | 3 |
| mlx | caveman | mlx-community/Phi-4-4bit | 2/28 | 7.1% | 0.0 | 3 |
| lms | opencode | google/gemma-4-31b-qat | 2/28 | 7.1% | 2.9 | 1 |
| lms | opencode | google/gemma-4-31b | 2/28 | 7.1% | 2.9 | 1 |
| lms | opencode | google/gemma-4-12b | 2/28 | 7.1% | 1.3 | 1 |
| lms | hermes | ibm/granite-4.1-30b | 2/28 | 7.1% | 252.2 | 1 |
| lms | hermes | google/gemma-4-e4b-qat | 2/28 | 7.1% | 3.6 | 1 |
| lms | hermes | google/gemma-4-e4b | 2/28 | 7.1% | 3.3 | 1 |
| lms | hermes | google/gemma-4-31b-qat | 2/28 | 7.1% | 3.9 | 1 |
| lms | hermes | google/gemma-4-31b | 2/28 | 7.1% | 4.1 | 1 |
| lms | hermes | google/gemma-4-12b-qat | 2/28 | 7.1% | 3.7 | 1 |
| lms | hermes | google/gemma-4-12b | 2/28 | 7.1% | 11.9 | 1 |
| lms | copilot | microsoft/phi-4-mini | 2/28 | 7.1% | 56.2 | 1 |
| lms | codex | google/gemma-4-31b-qat | 2/28 | 7.1% | 1.3 | 1 |
| lms | codex | google/gemma-4-31b | 2/28 | 7.1% | 1.1 | 1 |
| lms | codex | google/gemma-4-12b | 2/28 | 7.1% | 7.9 | 1 |
| lms | caveman | google/gemma-4-31b-qat | 2/28 | 7.1% | 1.1 | 1 |
| lms | caveman | google/gemma-4-31b | 2/28 | 7.1% | 1.1 | 1 |
| lms | caveman | google/gemma-4-12b | 2/28 | 7.1% | 1.2 | 1 |
| lms | aider | google/gemma-4-31b-qat | 2/28 | 7.1% | 4.6 | 1 |
| lms | aider | google/gemma-4-31b | 2/28 | 7.1% | 4.4 | 1 |
| ollama | caveman | phi4-mini:latest | 0/2 | 0.0% | 1.0 | 1 |
| mlx | copilot | /Users/jesper/.lmstudio/models/lmstudio-community/gemma-4-E2B-it-MLX-4bit | 0/2 | 0.0% | 121.0 | 1 |
| mlx | caveman | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 0/2 | 0.0% | 0.0 | 1 |

## Leaderboard — by model

| Runtime | Model | Pass | Pass% | Avg s |
|---------|-------|------|-------|-------|
| ollama | qwen3.6:35b-a3b-coding-mxfp8 | 2/2 | 100.0% | 38.0 |
| mlx | /Users/jesper/src/dotfiles/link-dir/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 2/2 | 100.0% | 362.0 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3.5-9B-MLX-4bit | 34/34 | 100.0% | 153.3 |
| lms | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 34/34 | 100.0% | 106.0 |
| lms | qwen/qwen3.6-35b-a3b | 373/376 | 99.2% | 72.9 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-Next-MLX-6bit | 32/34 | 94.1% | 106.8 |
| lms | google/gemma-4-26b-a4b-qat | 230/256 | 89.8% | 129.5 |
| ollama | gemma4-claude | 59/66 | 89.4% | 80.8 |
| lms | qwen/qwen3.5-9b | 321/370 | 86.8% | 271.4 |
| lms | qwen/qwen3-coder-30b | 157/188 | 83.5% | 92.4 |
| ollama | gemma4-26b-qat | 75/90 | 83.3% | 132.7 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/Qwen3-Coder-30B-A3B-Instruct-MLX-4bit | 55/66 | 83.3% | 163.3 |
| ollama | gpt-oss-20b | 64/80 | 80.0% | 58.9 |
| ollama | qwen3.6-35b-mlx | 175/246 | 71.1% | 67.2 |
| lms | qwen/qwen3-coder-next | 120/178 | 67.4% | 26.8 |
| lms | google/gemma-4-e2b | 97/161 | 60.2% | 24.3 |
| lms | google/gemma-4-12b-qat | 91/152 | 59.9% | 138.4 |
| lms | google/gemma-4-e2b-qat | 86/144 | 59.7% | 30.5 |
| lms | google/gemma-4-e4b | 88/154 | 57.1% | 53.4 |
| lms | google/gemma-4-e4b-qat | 78/137 | 56.9% | 52.0 |
| lms | ibm/granite-4.1-30b | 89/175 | 50.9% | 310.6 |
| lms | qwen/qwen3.6-27b | 4/8 | 50.0% | 269.5 |
| ollama | qwen2.5-coder:7b | 21/56 | 37.5% | 14.3 |
| ollama | qwen3.5-claude | 14/48 | 29.2% | 131.9 |
| ollama | qwen3.5:9b | 1/5 | 20.0% | 190.5 |
| lms | microsoft/phi-4-mini | 34/180 | 18.9% | 120.7 |
| lms | google/gemma-4-12b | 19/140 | 13.6% | 27.6 |
| mlx | mlx-community/Phi-4-4bit | 6/68 | 8.8% | 4.0 |
| ollama | phi4:latest | 2/28 | 7.1% | 0.9 |
| mlx | mlx-community/Phi-4-mini-instruct-4bit | 6/84 | 7.1% | 36.1 |
| lms | google/gemma-4-31b-qat | 10/140 | 7.1% | 2.8 |
| lms | google/gemma-4-31b | 10/140 | 7.1% | 2.7 |
| ollama | phi4-mini:latest | 2/30 | 6.7% | 1.0 |
| mlx | /Users/jesper/.lmstudio/models/lmstudio-community/gemma-4-E2B-it-MLX-4bit | 0/2 | 0.0% | 121.0 |

## Leaderboard — by adapter

| Adapter | Pass | Pass% | Avg s |
|---------|------|-------|-------|
| interpreter | 90/92 | 97.8% | 67.7 |
| goose | 73/82 | 89.0% | 64.4 |
| pi | 135/158 | 85.4% | 67.3 |
| cline | 94/124 | 75.8% | 443.0 |
| copilot | 148/224 | 66.1% | 130.2 |
| aider | 381/588 | 64.8% | 57.2 |
| caveman | 424/655 | 64.7% | 84.6 |
| codex | 342/591 | 57.9% | 103.5 |
| opencode | 379/661 | 57.3% | 59.7 |
| hermes | 325/699 | 46.5% | 113.4 |
