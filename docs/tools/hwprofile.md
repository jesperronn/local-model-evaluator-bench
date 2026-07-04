# hwprofile — hardware detection for local model benchmarking

Lightweight cross-platform hardware profiler that detects machine specs to help participants understand their capacity for running local models and agents. Works on macOS, Linux, and Windows (Git Bash/WSL/Cygwin). No elevated permissions required.

## Usage

```bash
# Default: human-readable detailed profile
bin/hwprofile

# Machine-readable JSON (for tooling/CI)
bin/hwprofile --json

# Compact one-liner summary
bin/hwprofile --minimal

# Help
bin/hwprofile --help
```

## Distribution

Designed to be distributed as a gist and run via:
```bash
curl https://gist.github.com/.../hwprofile | bash
```

The script is self-contained with no external dependencies beyond standard Unix utilities.

## What it detects

- **Machine**: Hostname, username, OS
- **Memory**: Total RAM, RAM in use, nearest benchmarked tier
- **Processor**: Model name, core count, base frequency (if available)
- **Storage**: Free disk space on root mount

## Output formats

- **Human** (default): Pretty-printed table with all details
- **JSON**: Machine-readable for tooling and CI pipelines
- **Minimal**: Single-line summary

## Tuning tip (Apple Silicon)

On Apple Silicon Macs, the GPU uses unified memory but macOS caps how much RAM the GPU can claim as "wired" memory (~75% of total by default). The human output displays a `sysctl` command to raise this cap if your machine has 16 GB or more total RAM:

```bash
sudo sysctl iogpu.wired_limit_mb=<MB>
```

This setting:
- **Resets on reboot** — apply it each time you need it
- **Requires `sudo`** — no way around it
- **Can starve the OS if set too high** — we suggest `(total_RAM_GB - 4) * 1024` MB to leave 4 GB for macOS
- **Helps larger models/contexts fit in VRAM** — useful when running large language models or deep agent loops

Close memory-heavy apps (Chrome, Docker) before applying the setting and running long inference tasks.
