#!/usr/bin/env python3
"""Load generator and latency probe for module 11 (stdlib only, python:3.12-alpine).

Sends GET requests at a fixed rate from CONC worker threads and prints one JSON
line per WINDOW seconds, then (when DURATION > 0) one final line with "final": true
covering the whole run.

Environment:
  URL        target, e.g. http://quote-api/quote          (required)
  RATE       total requests per second          (default 10)
  CONC       worker threads                     (default 4)
  DURATION   seconds to run, 0 = forever        (default 0)
  WINDOW     seconds per log line               (default 5)
  TIMEOUT    per-request timeout in seconds     (default 3)
  RETRY      1 = one immediate retry after a failure (default 0)
  HOSTHDR    optional Host header

A request counts as an error when it raises (timeout, reset, refused) or answers
anything but 2xx. Line format:
  {"t": 1731300000, "count": 50, "errors": 0, "p50_ms": 12, "p95_ms": 31, "max_ms": 40,
   "codes": {"200": 50}}
Latency is measured for the whole attempt including the retry.
"""
import http.client, json, os, threading, time
from urllib.parse import urlparse

U = urlparse(os.environ["URL"])
RATE = float(os.environ.get("RATE", "10"))
CONC = int(os.environ.get("CONC", "4"))
DURATION = float(os.environ.get("DURATION", "0"))
WINDOW = float(os.environ.get("WINDOW", "5"))
TIMEOUT = float(os.environ.get("TIMEOUT", "3"))
RETRY = os.environ.get("RETRY", "0") == "1"
HOSTHDR = os.environ.get("HOSTHDR")

lock = threading.Lock()
win = []          # (ms, code) for the current window
total = []        # same, whole run
stop = threading.Event()


def once():
    try:
        c = http.client.HTTPConnection(U.hostname, U.port or 80, timeout=TIMEOUT)
        c.request("GET", (U.path or "/") + ("?" + U.query if U.query else ""),
                  headers={"Host": HOSTHDR} if HOSTHDR else {})
        r = c.getresponse()
        r.read()
        c.close()
        return r.status
    except Exception:
        return 0


def worker():
    gap = CONC / RATE
    nxt = time.perf_counter() + (threading.get_ident() % 100) / 100.0 * gap
    while not stop.is_set():
        now = time.perf_counter()
        if now < nxt:
            time.sleep(min(nxt - now, 0.2))
            continue
        nxt += gap
        if nxt < now - 1:          # fell behind (slow target): do not burst to catch up
            nxt = now + gap
        t0 = time.perf_counter()
        code = once()
        if RETRY and not 200 <= code < 300:
            code = once()
        ms = (time.perf_counter() - t0) * 1000
        with lock:
            win.append((ms, code))
            total.append((ms, code))


def summary(rows, **extra):
    n = len(rows)
    lat = sorted(r[0] for r in rows)
    codes = {}
    for _, c in rows:
        codes[str(c)] = codes.get(str(c), 0) + 1
    pick = lambda q: int(lat[min(n - 1, int(q * n))]) if n else 0
    d = {"t": int(time.time()), "count": n,
         "errors": sum(1 for _, c in rows if not 200 <= c < 300),
         "p50_ms": pick(0.5), "p95_ms": pick(0.95), "max_ms": int(lat[-1]) if n else 0, "codes": codes}
    d.update(extra)
    return d


for _ in range(CONC):
    threading.Thread(target=worker, daemon=True).start()
start = time.time()
while True:
    time.sleep(WINDOW)
    with lock:
        rows, win[:] = list(win), []
    print(json.dumps(summary(rows)), flush=True)
    if DURATION and time.time() - start >= DURATION:
        break
stop.set()
time.sleep(min(TIMEOUT, 1) + 0.2)
with lock:
    rows = list(total)
print(json.dumps(summary(rows, final=True)), flush=True)
