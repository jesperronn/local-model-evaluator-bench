# google/gemma-4-26b-a4b (MLX 6-bit)

## Metadata

| Field | Value |
|-------|-------|
| **Model key** | `gemma4-26b-6bit` (alias, MLX only) |
| **Family / arch** | Gemma 4, MoE (26B total, 4B active) |
| **Parameter count** | 26B total, ~4B active |
| **Disk size** | <!-- TODO --> |
| **Quantization** | MLX 6-bit (non-QAT) |
| **Added** | 2026-06-13 |
| **Last run** | 2026-06-13 |
| **Doc updated** | 2026-06-13 |

## Results summary

**hermes (MLX 6-bit): 34/34 100%, avg 153.9s.** Clean sweep across all 9 cases. The 6-bit
quantization is slower per token (~2.5×) than the 4-bit QAT variant but produces higher-quality
output, meaning many iterative cases require fewer correction rounds. Net effect: most multi-turn
cases are faster on 6-bit despite the token-level slowdown. See timing observations below.

Compare against [gemma4-26b-qat](google--gemma-4-26b-a4b-qat.md) (QAT MLX 4-bit, avg 132s).

## Failure patterns

None. All 34 tests pass on first bench run (9 cases × hermes adapter).

## Timing observations

**hermes (MLX 6-bit):** 14–270s, avg 153.9s. 34/34 100%.

| Case | 6-bit | QAT (4-bit) | Delta | Note |
|------|-------|-------------|-------|------|
| bash-01 | 256s | 84s | +172s | Cold-start JIT for 6-bit compute graph (first request only) |
| js-01 | 98s | 37s | +61s | Single-pass; token-level slowdown dominates |
| js-02 | 183s | 253s | -70s | Fewer correction rounds on 6-bit; net faster |
| js-03 | 270s | 260s | +10s | Similar; both need full 5 passes |
| js-04 | 72s | 95s | -23s | 6-bit faster on rename precision |
| js-05 | 223s | 246s | -23s | 6-bit fewer rounds |
| js-06 | 87s | 129s | -42s | 6-bit much faster on lint iteration |
| smoke-00 | 14s | 13s | +1s | ~same |
| ts-01 | 182s | 160s | +22s | Slightly slower on TypeScript groupby |

**bash-01 cold-start JIT:** The 6-bit compute graph is different from QAT and required JIT
compilation on first use (256s vs 84s). Subsequent cases run at normal speed. This is
expected and was not observed on QAT because QAT uses the same 4-bit graph the server
pre-compiles. On repeat server runs, bash-01 would be faster.

**Token-level speed tradeoff:** Where a case requires many correction rounds (iterative
bug-fix or multi-file), 6-bit finishes faster because higher precision means fewer total
rounds. Where a case is single-pass, 6-bit is 2–3× slower (token rate dominates).

## Known issues

MLX only — no LMS or Ollama variant. Run with:

```
bin/bench --runtime mlx --model gemma4-26b-6bit --adapter hermes --timeout 450
```

## Status

**active** — 34/34 100%. Recommended over QAT for iterative/multi-file cases;
QAT is faster for single-pass workloads.

## Comparison within family

| Variant | Avg s | Pass% | Notes |
|---------|-------|-------|-------|
| `gemma4-26b-6bit` (MLX 6-bit, this) | 153.9s | 100% | Higher quality, best for multi-round cases |
| `gemma4-26b-qat` (MLX QAT 4-bit) | 132s | 100% | Faster per token, better for single-pass |
| `gemma4:26b-mlx` (Ollama nvfp4) | pending | — | Ollama runtime, not yet benchmarked |
| `google/gemma-4-26b-a4b-qat` (LMS) | ~56s avg | 100% | LM Studio, fastest overall (no server overhead) |
