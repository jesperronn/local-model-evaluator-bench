# Further Reading

Additional reference materials beyond the core setup and usage docs.

## Hardware & Performance

- **[HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md)** — Per-tier model recommendations and concurrency settings for 128 GB, 64 GB, 32 GB, 24 GB machines
- **[TESTING-STRATEGY.md](TESTING-STRATEGY.md)** — How to test adapters and models across hardware tiers
- **[RUNTIME-OMLX.md](RUNTIME-OMLX.md)** — oMLX runtime setup and optimization

## Models & Benchmarking

- **[CASES.md](CASES.md)** — All 150+ test cases: what each tests, difficulty, language, how to add more
- **[QUESTION-SUITE.md](QUESTION-SUITE.md)** — The evaluation question set used for agent scoring
- **[SCORING.md](SCORING.md)** — How pass/fail is determined and accuracy metrics
- **[SMALL-MODEL-EVALUATION.md](SMALL-MODEL-EVALUATION.md)** — Results and findings from smaller model benchmarking
- **[MODEL-RESEARCH.md](MODEL-RESEARCH.md)** — Research notes on various models: quantization, context windows, performance

## Adapters & Tools

- **[ADAPTER-SETUP.md](ADAPTER-SETUP.md)** — How to install and configure individual adapters (aider, cline, hermes, opencode, pi)
- **[AGENT-SELECTION.md](AGENT-SELECTION.md)** — Guide to choosing which agent for your use case
- **[CARD-SPEC.md](CARD-SPEC.md)** — Card file format specification (test cases and eval metrics)
- **[AGENT-EVAL-SUITE.md](AGENT-EVAL-SUITE.md)** — Evaluating agents on question suites

## Development & Architecture

- **[CLI-DISCOVERY.md](CLI-DISCOVERY.md)** — Pattern for building CLI tools with next-steps guidance (for developers building bin/* tools)
- **[WORKFLOW.md](WORKFLOW.md)** — Adapter and model evaluation workflow; how to add new adapters and manage compatibility
- **[ADDING-CASES.md](ADDING-CASES.md)** — How to add new test cases to the suite
- **[MODEL-DISCOVERY.md](MODEL-DISCOVERY.md)** — How models are discovered on various runtimes (Ollama, LM Studio, oMLX)

## Project Context

- **[PURPOSE.md](PURPOSE.md)** — Why this project exists: what it measures and what it doesn't measure
- **[AGENT-SELECTION.md](AGENT-SELECTION.md)** — Who are the agents being tested and why
- **[ROADMAP-END-GOALS.md](ROADMAP-END-GOALS.md)** — Where the project is headed; end goals and phases

## Design & Decision Rationale

For detailed decision rationale and prior planning, see **[archived/](archived/README.md)**:
- Why we chose local-only (no cloud models)
- Why we use oMLX for MLX inference
- How CLI tool consolidation was planned
- Other architectural decisions

---

## Quick Reference by Task

### "I want to understand why we built this"
→ [PURPOSE.md](PURPOSE.md)

### "I want to add a new test case"
→ [ADDING-CASES.md](ADDING-CASES.md) · [CASES.md](CASES.md)

### "I want to understand how adapters work"
→ [WORKFLOW.md](WORKFLOW.md) · [ADAPTER-SETUP.md](ADAPTER-SETUP.md)

### "I want to add a new adapter"
→ [WORKFLOW.md](WORKFLOW.md#1-adding-a-new-adapter)

### "I want to tune performance on my hardware tier"
→ [HARDWARE-RECOMMENDATIONS.md](HARDWARE-RECOMMENDATIONS.md) · [TESTING-STRATEGY.md](TESTING-STRATEGY.md)

### "I want to understand model quantization/performance"
→ [MODEL-RESEARCH.md](MODEL-RESEARCH.md) · [SMALL-MODEL-EVALUATION.md](SMALL-MODEL-EVALUATION.md)

### "I want to see past decisions and rationale"
→ [archived/](archived/README.md)

### "I want to build a new CLI tool"
→ [CLI-DISCOVERY.md](CLI-DISCOVERY.md)

---

## External Resources

### Runtime Selection & Benchmarks
- [Choosing an On-Device LLM Runtime on Apple Silicon: A Decision Framework Beyond Benchmarks](https://medium.com/@michael.hannecke/choosing-an-on-device-llm-runtime-on-apple-silicon-a-decision-framework-beyond-benchmarks-2449067b8b67) — context handling, API surface, agentic fit (beyond tok/s)
- [Local LLM on iPhone: MLX vs llama.cpp vs LiteRT-LM vs CoreML](https://rockyshikoku.medium.com/local-llm-on-iphone-which-runtime-is-actually-fastest-58096685481e) — cross-runtime speed on Apple Silicon (May 2026)
- [Prefix Caching: SGLang vs vLLM](https://medium.com/byte-sized-ai/prefix-caching-sglang-vs-vllm-token-level-radix-tree-vs-block-level-hashing-b99ece9977a1) — token-level radix tree vs block-level hashing

### Apple Silicon & MLX
- [WWDC26 #232: Run Local Agentic AI on Mac Using MLX](https://developer.apple.com/videos/play/wwdc2026/232/) — mlx_lm.server, continuous batching, M5 Neural Accelerators, distributed inference
- [WWDC26 #233: Distributed Inference & Training with MLX](https://developer.apple.com/videos/play/wwdc2026/233/) — multi-Mac model sharding
- [Exploring LLMs with MLX and M5 GPU Neural Accelerators](https://machinelearning.apple.com/research/exploring-llms-mlx-m5) — Apple ML Research on kernel selection and throughput
- [LM Studio MLX Engine — Agentic Workloads (v1.8.5, June 2026)](https://lmstudio.ai/blog/mlx-engine-agentic-workloads) — disk-backed KV cache checkpointing

### Model Architectures for Local Inference
- [Gemma 4 12B Developer Guide](https://developers.googleblog.com/gemma-4-12b-the-developer-guide/) — LiteRT-LM, MoE variants (E2B/E4B), on-device deployment
- [Blazing Fast On-Device GenAI with LiteRT-LM](https://developers.googleblog.com/blazing-fast-on-device-genai-with-litert-lm/) — MTP speculative decoding, session save/restore, constrained decoding
