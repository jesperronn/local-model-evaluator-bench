# Instructions for Model Editing and Verification

These instructions guide an AI model (like GPT-4 or Claude) on how to perform suggested code changes, test them against existing functionality, and verify the implementation's correctness in a development environment.

## Goal

The primary goal is to modify existing codebases (`adapters/*.sh`, `bin/*`, etc.) to ensure they correctly interface with a local Language Model (LM Studio) using standardized OpenAI API parameters, while maintaining backward compatibility with the surrounding testing framework.

## Steps for Model Implementation

### 1. Code Modification
Use the provided file paths and specific replacement rules. When modifying shell scripts (`.sh` files), always aim to replace complex, multi-line `exec` blocks with concise calls that leverage environment variables like `$LMS_BASE_URL` and `$LMS_API_KEY`.

**Example Target Structure (OpenAI compatibility):**
```bash
# Original: Complex hardcoded flags or custom providers.
# New Goal: Use standardized parameters for OpenAI compatibility.
exec <tool> exec \
  --model "$MODEL_ID" \
  --openai-api-base "$LMS_BASE_URL" \
  --openai-api-key "$LMS_API_KEY" \
  "$PROMPT"
```

### 2. Verification Strategy (Mandatory)
After every set of changes, perform the following verification cycle:
1.  **Lint/Style Check:** Run all standard linting and typechecking commands available in the project (`npm run lint`, `npm run typecheck`, etc.).
2.  **Smoke Test:** Execute `./bin/smoke <model-id>` to ensure basic connectivity and functionality across all adapters with a small, reliable model (e.g., `google/gemma-4-e2b-qat`).
3.  **Specific Feature Tests:** Run any manual or dedicated tests for the modified component.

### 3. Committing Changes
Only commit changes after **all** steps above pass successfully. Use clear, structured commit messages (e.g., `fix(adapter): ...`) to isolate functional fixes from general refactoring.

---
*Remember to use the file system tools (`read`, `edit`, `grep`, etc.) as needed during development.*