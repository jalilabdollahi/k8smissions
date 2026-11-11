#!/usr/bin/env python3
"""Tiny Git smart-HTTP server (stdlib only) for the K8sMissions Git fixture.

Serves bare repos under /srv/git at /cgi-bin/git/<name>.git (clone, fetch, push).
Repos under /srv/git/private/ are served at /cgi-bin/git/private/<name>.git and
need HTTP basic auth (GIT_PRIVATE_USER / GIT_PRIVATE_PASSWORD).
It runs `git upload-pack` / `git receive-pack --stateless-rpc`, which is all
the smart protocol is.
"""
import base64
import gzip
import hmac
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = "/srv/git"
PREFIX = "/cgi-bin/git/"
USER = os.environ.get("GIT_PRIVATE_USER", "ci-bot")
PASSWORD = os.environ.get("GIT_PRIVATE_PASSWORD", "ci-bot-secret")


def pkt(line: str) -> bytes:
    return b"%04x" % (len(line) + 4) + line.encode()


class Handler(BaseHTTPRequestHandler):
    server_version = "gitserver"

    def log_message(self, fmt, *args):
        print("%s %s" % (self.address_string(), fmt % args), flush=True)

    def reply(self, code, body=b"", ctype="text/plain", headers=()):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        for k, v in headers:
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def route(self):
        """Return (repo_dir, rest) or None after sending an error."""
        path = self.path.split("?", 1)[0]
        if path == "/":
            self.reply(200, b"ok\n")
            return None
        if not path.startswith(PREFIX) or ".git/" not in path:
            self.reply(404, b"not found\n")
            return None
        rel, rest = path[len(PREFIX):].split(".git/", 1)
        if rel.startswith("private/"):
            auth = self.headers.get("Authorization", "")
            ok = False
            if auth.startswith("Basic "):
                try:
                    u, _, p = base64.b64decode(auth[6:]).decode().partition(":")
                    ok = hmac.compare_digest(u, USER) and hmac.compare_digest(p, PASSWORD)
                except Exception:
                    ok = False
            if not ok:
                self.reply(401, b"authentication required\n", headers=[("WWW-Authenticate", 'Basic realm="private"')])
                return None
        repo = os.path.realpath(os.path.join(ROOT, rel + ".git"))
        if not repo.startswith(ROOT + "/") or not os.path.isdir(repo):
            self.reply(404, b"repository not found\n")
            return None
        return repo, rest

    def git(self, service, repo, advertise, stdin=b""):
        env = dict(os.environ)
        proto = self.headers.get("Git-Protocol", "")
        if proto:
            env["GIT_PROTOCOL"] = proto
        cmd = ["git", service[4:], "--stateless-rpc"] + (["--advertise-refs"] if advertise else []) + [repo]
        return subprocess.run(cmd, input=stdin, capture_output=True, env=env), proto

    def do_GET(self):
        r = self.route()
        if not r:
            return
        repo, rest = r
        service = self.path.partition("service=")[2].split("&")[0]
        if rest != "info/refs" or service not in ("git-upload-pack", "git-receive-pack"):
            return self.reply(403, b"only the smart protocol is served\n")
        p, proto = self.git(service, repo, True)
        if p.returncode:
            return self.reply(500, p.stderr)
        head = b"" if "version=2" in proto else pkt("# service=%s\n" % service) + b"0000"
        self.reply(200, head + p.stdout, "application/x-%s-advertisement" % service)

    def read_body(self):
        if "chunked" in self.headers.get("Transfer-Encoding", ""):
            data = b""
            while True:
                n = int(self.rfile.readline().split(b";")[0].strip() or b"0", 16)
                if n == 0:
                    self.rfile.readline()
                    break
                data += self.rfile.read(n)
                self.rfile.readline()
        else:
            data = self.rfile.read(int(self.headers.get("Content-Length", "0")))
        if self.headers.get("Content-Encoding") == "gzip":
            data = gzip.decompress(data)
        return data

    def do_POST(self):
        r = self.route()
        if not r:
            return
        repo, rest = r
        if rest not in ("git-upload-pack", "git-receive-pack"):
            return self.reply(403, b"only the smart protocol is served\n")
        p, _ = self.git(rest, repo, False, self.read_body())
        if p.stderr:
            print(p.stderr.decode(errors="replace"), flush=True)
        self.reply(200, p.stdout, "application/x-%s-result" % rest)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
