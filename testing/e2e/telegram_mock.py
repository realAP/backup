# minimal telegram api: stores the text of every sendMessage call
import os
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
        text = urllib.parse.parse_qs(body).get("text", [""])[0]
        with open("/out/messages.log", "a") as f:
            f.write(text + "\n---\n")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{"ok":true}')

    def log_message(self, *args):
        pass


# runs as root, the host user must still be able to truncate and delete the log
os.umask(0)
HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
