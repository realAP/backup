from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os

LOG_DIR = "/logs"
LOG_FILE = os.path.join(LOG_DIR, "messages.log")


class TelegramMockHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode()
        os.makedirs(LOG_DIR, exist_ok=True)
        with open(LOG_FILE, "a") as f:
            f.write(body + "\n")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": True}).encode())

    def log_message(self, format, *args):
        # Suppress default request logging
        pass


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8080), TelegramMockHandler)
    print("Mock Telegram server listening on port 8080")
    server.serve_forever()
