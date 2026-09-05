#!/usr/bin/env python3
"""
HTTP wrapper that transforms LiteLLM's OpenAI-format /v1/models response
into Ollama format that Codex expects.

LiteLLM returns: {"data":[{"id":"...", ...}], "object":"list"}
Codex expects:  {"models":[{"name":"...", ...}]}

Routes all other requests through unchanged.

Uses only built-in Python libraries (no external dependencies).
"""

import sys
import json
import urllib.request
import urllib.error
import http.server
import socketserver
from urllib.parse import urlparse, urlunparse

if len(sys.argv) < 3:
    print("Usage: codex-models-wrapper.py <listen_port> <target_url>")
    sys.exit(1)

LISTEN_PORT = int(sys.argv[1])
TARGET_URL = sys.argv[2]


def transform_models_response(openai_response: dict) -> dict:
    """Transform OpenAI format to Ollama format."""
    if isinstance(openai_response, dict) and "data" in openai_response:
        # Transform each model from OpenAI format to Ollama format
        models = []
        for item in openai_response.get("data", []):
            model = {
                "name": item.get("id", ""),
                "model": item.get("id", ""),
                "modified_at": item.get("created", 0),
                "size": 0,
                "digest": "",
            }
            models.append(model)
        return {"models": models}
    return openai_response


class ModelsTransformHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler that transforms /v1/models responses."""

    def do_GET(self):
        self.proxy_request()

    def do_POST(self):
        self.proxy_request()

    def do_PUT(self):
        self.proxy_request()

    def do_DELETE(self):
        self.proxy_request()

    def do_PATCH(self):
        self.proxy_request()

    def proxy_request(self):
        """Proxy the request to the target server, transforming responses as needed."""
        # Build the target URL
        target_path = self.path
        target_url = f"{TARGET_URL}{target_path}"
        # Debug: log the request
        if "/models" in target_path:
            import sys
            print(f"[WRAPPER] {self.command} {target_url}", file=sys.stderr, flush=True)

        # Prepare headers
        headers = {}
        for header, value in self.headers.items():
            if header.lower() not in ['host', 'connection', 'content-length']:
                headers[header] = value

        # Get request body if present
        body = None
        if self.command in ["POST", "PUT", "PATCH"]:
            content_length = int(self.headers.get('content-length', 0))
            if content_length > 0:
                body = self.rfile.read(content_length)

        try:
            # Make the request to the target server
            req = urllib.request.Request(target_url, data=body, headers=headers, method=self.command)
            with urllib.request.urlopen(req, timeout=300) as response:
                response_body = response.read()
                response_headers = dict(response.headers)

                # Check if this is a /models or /v1/models request and transform the response
                if (self.path == "/v1/models" or self.path.startswith("/models")) and self.command == "GET":
                    try:
                        data = json.loads(response_body.decode('utf-8'))
                        transformed = transform_models_response(data)
                        response_body = json.dumps(transformed).encode('utf-8')
                        response_headers['content-length'] = str(len(response_body))
                    except (json.JSONDecodeError, UnicodeDecodeError, ValueError):
                        # If transformation fails, pass through original response
                        pass

                # Send response back to client
                self.send_response(response.status)
                for header, value in response_headers.items():
                    if header.lower() != 'transfer-encoding':
                        self.send_header(header, value)
                self.end_headers()
                self.wfile.write(response_body)

        except urllib.error.HTTPError as e:
            # Forward HTTP errors
            self.send_response(e.code)
            self.send_header('content-type', 'application/json')
            self.end_headers()
            error_response = json.dumps({"error": str(e)}).encode('utf-8')
            self.wfile.write(error_response)
        except Exception as e:
            # Handle other errors
            self.send_response(503)
            self.send_header('content-type', 'application/json')
            self.end_headers()
            error_response = json.dumps({"error": str(e)}).encode('utf-8')
            self.wfile.write(error_response)

    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


if __name__ == "__main__":
    handler = ModelsTransformHandler
    with socketserver.TCPServer(("127.0.0.1", LISTEN_PORT), handler) as httpd:
        print(f"Models wrapper listening on http://127.0.0.1:{LISTEN_PORT}", file=sys.stderr)
        sys.stderr.flush()
        httpd.serve_forever()
