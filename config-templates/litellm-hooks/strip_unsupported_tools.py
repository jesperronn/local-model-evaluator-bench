"""
LiteLLM proxy hooks: drop unsupported tools and convert JSON tool calls to raw text.

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

Because the tool definition is stripped, models (trained on copilot) still output
JSON-formatted apply_patch calls. The post-call hook detects these and converts
them to raw patch text that copilot expects.

Mounted read-only into the litellm-database image at
/app/hooks/strip_unsupported_tools.py and enabled via
litellm_settings.callbacks in config-templates/litellm.yaml.
"""

import json
import re
from litellm.integrations.custom_logger import CustomLogger


def extract_json_tool_call(content: str) -> dict | None:
    """Parse a JSON tool call from model text output.

    Handles:
      - Raw JSON: {"name": "fn", "arguments": {...}}
      - Code-fenced: ```json\n{...}\n```
    """
    s = content.strip()
    # Strip opening fence (```json or ```)
    s = re.sub(r"^```\w*\n?", "", s)
    # Strip closing fence
    s = re.sub(r"\n?```$", "", s).strip()
    if not s.startswith("{"):
        return None
    try:
        call = json.loads(s)
    except json.JSONDecodeError:
        return None
    if not isinstance(call, dict) or "name" not in call or "arguments" not in call:
        return None
    return call


class StripUnsupportedTools(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        tools = data.get("tools")
        if not tools:
            return data
        kept = [t for t in tools if t.get("type", "function") == "function"]
        if len(kept) != len(tools):
            data["tools"] = kept
        return data

    async def async_post_call_success_hook(self, user_api_key_dict, response, **kwargs):
        """Convert JSON tool calls (from models trained on copilot) to raw text.

        When apply_patch tool definition is stripped from the request, models still
        output JSON tool calls like {"name": "apply_patch", "arguments": {"patch": "..."}}.
        Copilot expects raw patch text, not JSON. This hook converts JSON calls to raw.
        """
        if not response or not hasattr(response, 'choices'):
            return response

        for choice in response.choices:
            if not hasattr(choice, 'message'):
                continue
            msg = choice.message
            content = getattr(msg, 'content', None)
            if not content:
                continue

            # Try to parse as JSON tool call
            tool_call = extract_json_tool_call(content)
            if not tool_call:
                continue

            # If it's an apply_patch call, extract the raw patch content
            if tool_call.get('name') == 'apply_patch':
                args = tool_call.get('arguments', {})
                if isinstance(args, str):
                    try:
                        args = json.loads(args)
                    except json.JSONDecodeError:
                        pass

                if isinstance(args, dict) and 'patch' in args:
                    patch_content = args['patch']
                    if isinstance(patch_content, str):
                        # Replace the JSON content with raw patch text
                        msg.content = patch_content
                        # Clear tool_calls since we've converted to text
                        if hasattr(msg, 'tool_calls'):
                            msg.tool_calls = None
                        if hasattr(choice, 'finish_reason'):
                            choice.finish_reason = 'stop'

        return response


proxy_handler_instance = StripUnsupportedTools()
