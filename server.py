#!/usr/bin/env python3
import http.server
import socketserver
import os

class GodotHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()

if __name__ == '__main__':
    port = 8000
    os.chdir('build')
    with socketserver.TCPServer(("", port), GodotHTTPRequestHandler) as httpd:
        print(f"Serving Godot HTML export at http://localhost:{port}")
        httpd.serve_forever()
