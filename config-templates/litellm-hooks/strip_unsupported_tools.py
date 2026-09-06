"""
LiteLLM proxy pre-call hook: drop tool definitions our local backends can't
handle before the request reaches them.

Copilot CLI always advertises its built-in `apply_patch` tool with
`{"type": "custom", "custom": {...freeform grammar...}}` — an OpenAI
*Responses API* tool shape, not a Chat Completions `function` tool. None of
our local runtimes (lms, ollama, mlx, omlx, mtplx) implement custom/freeform
tools; forwarding one to a plain OpenAI-compatible chat/completions backend
makes the underlying provider call return None instead of a stream, which
litellm-proxy then crashes on with a bare
`TypeError: 'async for' requires an object with __aiter__ method, got NoneType`
deep in its own streaming-iterator hook chain (see
litellm/proxy/proxy_server.py::async_data_generator and
litellm/proxy/hooks/responses_id_security.py). Stripping the unsupported tool
here avoids the crash instead of chasing it downstream.

Mounted read-only into the litellm-database image at
/app/hooks/strip_unsupported_tools.py and enabled via
litellm_settings.callbacks in config-templates/litellm.yaml.
"""

import json
import sys
from litellm.integrations.custom_logger import CustomLogger


class StripUnsupportedTools(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        # Codex always sends a top-level "client_metadata" field on every
        # /v1/responses request (session/thread/turn bookkeeping — see
        # docs/tools/codex.md and adapters/codex.sh). litellm's real "openai"
        # provider handles this fine (its Responses-API-native path either
        # forwards or maps it), but our local routes use
        # custom_llm_provider: "custom_openai" (see the long comment in
        # config-templates/litellm.yaml for why: it's what makes litellm use
        # the Responses<->chat-completions bridge for non-OpenAI backends
        # instead of trying to hit a /responses route none of them have).
        # That bridge's generic handler passes unrecognized top-level request
        # fields straight through to the plain `openai` Python SDK's
        # `AsyncCompletions.create(**kwargs)` call, which rejects any keyword
        # it doesn't know — crashing every codex turn with
        # "AsyncCompletions.create() got an unexpected keyword argument
        # 'client_metadata'" (confirmed in litellm-proxy container logs,
        # litellm 1.97.0). None of our local runtimes use this field for
        # anything, so drop it before it reaches the bridge.
        data.pop("client_metadata", None)

        # Copilot CLI replays its own prior tool calls back into conversation
        # history as {"type": "custom", "custom": {"name": ..., "input": ...}}
        # (its internal Responses-API-shaped record of the apply_patch call),
        # even though the tool call was answered as a Chat Completions
        # `function` call on the wire. A plain OpenAI-compatible backend
        # requires every assistant tool_call to carry `function.name`, so
        # forwarding the "custom" shape as-is fails with "assistant tool_call
        # is missing a name". Normalize any such history entries back to the
        # `function` shape before sending.
        for m in data.get("messages", []) or []:
            if m.get("role") != "assistant" or not m.get("tool_calls"):
                continue
            for tc in m["tool_calls"]:
                if not isinstance(tc, dict) or tc.get("type") != "custom":
                    continue
                custom = tc.get("custom", {}) or {}
                tc["type"] = "function"
                tc["function"] = {
                    "name": custom.get("name", "apply_patch"),
                    "arguments": custom.get("input", "{}"),
                }
                tc.pop("custom", None)

        tools = data.get("tools")
        if not tools:
            return data

        # Debug: log incoming tools
        print(f"[StripUnsupportedTools] Received {len(tools)} tool(s):", file=sys.stderr, flush=True)
        for i, t in enumerate(tools):
            custom_name = "?"
            if 'custom' in t:
                custom_name = str(type(t.get('custom')))
                if isinstance(t.get('custom'), dict):
                    custom_name = str(list(t.get('custom', {}).keys())[:3])  # First 3 keys
            print(f"[StripUnsupportedTools] Tool[{i}]: type={t.get('type')}, name={t.get('name')}, function_name={t.get('function', {}).get('name')}, custom_keys={custom_name}", file=sys.stderr, flush=True)

        # Keep function tools, convert custom tools to function tools where possible
        kept = []
        for t in tools:
            tool_type = t.get("type", "function")

            if tool_type == "function":
                kept.append(t)
            elif tool_type == "custom":
                # Check if this is the apply_patch custom tool from Copilot CLI
                # Copilot sends: {"type": "custom", "custom": {...freeform grammar...}}
                custom_def = t.get("custom", {})

                # Try to identify apply_patch by looking at the custom definition
                # or by any other identifier in the tool
                is_apply_patch = False

                # Check if "name" field exists at top level (sometimes custom tools have it)
                if t.get("name") == "apply_patch":
                    is_apply_patch = True
                # Check in custom definition
                elif isinstance(custom_def, dict) and custom_def.get("name") == "apply_patch":
                    is_apply_patch = True
                # Fallback: check function key (defensive)
                elif t.get("function", {}).get("name") == "apply_patch":
                    is_apply_patch = True

                if is_apply_patch:
                    # Convert apply_patch from custom to function tool so it's compatible
                    # with local runtimes. The model can still output JSON, but it will be
                    # recognized as a tool call instead of free text.
                    func_tool = {
                        "type": "function",
                        "function": {
                            "name": "apply_patch",
                            "description": "Apply a unified diff patch to edit files",
                            "parameters": {
                                "type": "object",
                                "properties": {
                                    "patch": {
                                        "type": "string",
                                        "description": "The unified diff patch to apply, starting with *** Begin Patch"
                                    }
                                },
                                "required": ["patch"]
                            }
                        }
                    }
                    kept.append(func_tool)

        if len(kept) != len(tools):
            print(f"[StripUnsupportedTools] Kept {len(kept)}/{len(tools)} tool(s)", file=sys.stderr, flush=True)
            for i, t in enumerate(kept):
                print(f"[StripUnsupportedTools] Kept[{i}]: type={t.get('type')}, name={t.get('name') or t.get('function', {}).get('name')}", file=sys.stderr, flush=True)
        data["tools"] = kept
        return data

    async def async_post_call_success_hook(self, user_api_key_dict, response, **kwargs):
        """No-op post-call hook to satisfy litellm hook interface."""
        return response


proxy_handler_instance = StripUnsupportedTools()
