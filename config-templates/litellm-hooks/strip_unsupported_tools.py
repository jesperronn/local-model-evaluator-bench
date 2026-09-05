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
