#!/usr/bin/env python3
"""Minimal GitHub webhook HTTP listener for Flashgap auto-deploy."""

from __future__ import annotations

import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_HOOK = SCRIPT_DIR / "github-deploy-hook.sh"
HOST = os.environ.get("FLASHGAP_WEBHOOK_HOST", "127.0.0.1")
PORT = int(os.environ.get("FLASHGAP_WEBHOOK_PORT", "9876"))
HOOK_SCRIPT = Path(os.environ.get("FLASHGAP_DEPLOY_HOOK_SCRIPT", str(DEFAULT_HOOK)))


class DeployWebhookHandler(BaseHTTPRequestHandler):
    server_version = "FlashgapDeployWebhook/1.0"

    def do_POST(self) -> None:
        if self.path not in ("/", "/flashgap-deploy-hook"):
            self.send_error(404, "Not Found")
            return

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)

        env = os.environ.copy()
        env["GITHUB_EVENT"] = self.headers.get("X-GitHub-Event", "")
        env["GITHUB_SIGNATURE_256"] = self.headers.get("X-Hub-Signature-256", "")

        try:
            result = subprocess.run(
                ["bash", str(HOOK_SCRIPT)],
                input=body,
                capture_output=True,
                env=env,
                check=False,
            )
        except OSError as exc:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f"Hook execution failed: {exc}\n".encode())
            return

        if result.returncode == 1:
            self.send_response(401)
            self.end_headers()
            self.wfile.write(result.stderr or b"Unauthorized\n")
            return

        if result.returncode != 0:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(result.stderr or b"Deploy failed\n")
            return

        self.send_response(202)
        self.end_headers()
        payload = result.stdout if result.stdout else b"Accepted\n"
        self.wfile.write(payload)

    def log_message(self, fmt: str, *args: object) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def main() -> None:
    if not HOOK_SCRIPT.is_file():
        sys.stderr.write(f"ERROR: hook script not found: {HOOK_SCRIPT}\n")
        sys.exit(1)

    server = ThreadingHTTPServer((HOST, PORT), DeployWebhookHandler)
    sys.stderr.write(f"Listening on http://{HOST}:{PORT}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        sys.stderr.write("Shutting down.\n")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
