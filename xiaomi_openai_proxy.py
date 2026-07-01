#!/usr/bin/env python3
import json
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

TARGET_BASE = os.environ.get("XIAOMI_TARGET_BASE", "https://token-plan-cn.xiaomimimo.com/v1")
SERVED_MODEL = os.environ.get("XIAOMI_PROXY_MODEL", "xiaomi-v2.5-pro")
TARGET_MODEL = os.environ.get("XIAOMI_TARGET_MODEL", "xiaomi-v2.5-pro")

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.log_date_time_string(), fmt % args), flush=True)

    def _send_json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.rstrip("/") in ("/v1/models", "/models"):
            return self._send_json(200, {
                "object": "list",
                "data": [
                    {
                        "id": SERVED_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "xiaomi"
                    }
                ]
            })

        return self._send_json(404, {"error": f"unsupported GET {self.path}"})

    def do_POST(self):
        if self.path.startswith("/v1/"):
            target_url = TARGET_BASE + self.path[len("/v1"):]
        else:
            target_url = TARGET_BASE + self.path

        length = int(self.headers.get("content-length", "0"))
        body = self.rfile.read(length) if length else b""

        try:
            data = json.loads(body.decode("utf-8"))
            if isinstance(data, dict):
                data["model"] = TARGET_MODEL
                body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        except Exception:
            pass

        api_key = os.environ.get("OPENAI_API_KEY", "")
        headers = {
            # 注意：这里强制使用小米真实 key，不使用 OpenClaw 传来的 dummy VLLM key
            "Authorization": f"Bearer {api_key}",
            "Content-Type": self.headers.get("Content-Type", "application/json"),
        }

        req = urllib.request.Request(
            target_url,
            data=body,
            headers=headers,
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=300) as resp:
                resp_body = resp.read()
                self.send_response(resp.status)
                for k, v in resp.headers.items():
                    if k.lower() not in ("transfer-encoding", "connection"):
                        self.send_header(k, v)
                self.end_headers()
                self.wfile.write(resp_body)
        except urllib.error.HTTPError as e:
            error_body = e.read()
            error_text = error_body.decode("utf-8", errors="replace")
            print(
                f"[upstream error] status={e.code} model={TARGET_MODEL} body={error_text[:2000]}",
                flush=True,
            )
            self.send_response(e.code)
            content_type = e.headers.get("Content-Type", "application/json")
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(error_body)))
            self.end_headers()
            self.wfile.write(error_body)
        except Exception as e:
            print(f"[proxy error] {type(e).__name__}: {e}", flush=True)
            return self._send_json(502, {"error": str(e)})

if __name__ == "__main__":
    port = int(os.environ.get("XIAOMI_PROXY_PORT", "8000"))
    print(
        f"Proxy listening on http://127.0.0.1:{port}/v1 -> {TARGET_BASE}, "
        f"served_model={SERVED_MODEL}, target_model={TARGET_MODEL}",
        flush=True,
    )
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
