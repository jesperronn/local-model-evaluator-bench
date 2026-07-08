# Workshop A — pre-installed agent tooling (Node + pi + opencode + bin/verify's
# runtime deps). Does NOT contain LM Studio/Ollama: those need native GPU
# access (Metal on Mac), which Docker Desktop cannot pass through. The model
# runtime stays on the host; this container only replaces the "npm install,
# wrong Node version, PATH issues" part of setup.
#
# Build:  docker compose build
# Run:    docker compose run --rm agent
# Inside: bin/verify --lms --verbose
#         bin/verify --agent pi --lms --verbose
#         cd demo-repo/01-slugify-bug && pi --provider lmstudio --model qwen/qwen3.6-35b-a3b
FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash curl git jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @earendil-works/pi-coding-agent opencode-ai

WORKDIR /workspace
CMD ["bash"]
