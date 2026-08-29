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

from litellm.integrations.custom_logger import CustomLogger


class StripUnsupportedTools(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        tools = data.get("tools")
        if not tools:
            return data
        kept = [t for t in tools if t.get("type", "function") == "function"]
        if len(kept) != len(tools):
            data["tools"] = kept
        return data


proxy_handler_instance = StripUnsupportedTools()
