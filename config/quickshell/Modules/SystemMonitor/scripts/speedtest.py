#!/usr/bin/env python3
import http.client
import json
import re
import statistics
import sys
import threading
import time
import urllib.parse
import urllib.request

FALLBACK_TOKEN = "YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm"
SITE = "https://fast.com/"
API = "https://api.fast.com/netflix/speedtest/v2"
CONNECTIONS = 5
PHASE_SECONDS = float(sys.argv[1]) if len(sys.argv) > 1 else 7.0
PAYLOAD = 25 * 1024 * 1024
CHUNK = 64 * 1024
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Minflair"}


def emit(**kw):
    sys.stdout.write(json.dumps(kw) + "\n")
    sys.stdout.flush()


def fetch(url, timeout=10):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read(8 << 20)


def fresh_token():
    page = fetch(SITE).decode("utf-8", "ignore")
    m = re.search(r"app-[a-z0-9]+\.js", page)
    if not m:
        raise RuntimeError("fast.com script not found")
    script = fetch(urllib.parse.urljoin(SITE, m.group(0))).decode("utf-8", "ignore")
    t = re.search(r'token:"([^"]+)"', script)
    if not t:
        raise RuntimeError("fast.com token not found")
    return t.group(1)


def targets_with(token):
    q = urllib.parse.urlencode({"https": "true", "token": token, "urlCount": CONNECTIONS})
    data = json.loads(fetch(API + "?" + q))
    urls = [t["url"] for t in data.get("targets", []) if t.get("url")]
    if not urls:
        raise RuntimeError("no test servers returned")
    return urls


def get_targets():
    try:
        return targets_with(FALLBACK_TOKEN)
    except urllib.error.HTTPError as e:
        if e.code not in (401, 403):
            raise
    token = fresh_token()
    if token == FALLBACK_TOKEN:
        raise RuntimeError("token rejected")
    return targets_with(token)


def ping(url):
    def probe():
        req = urllib.request.Request(url, headers=dict(UA, Range="bytes=0-0"))
        t = time.perf_counter()
        with urllib.request.urlopen(req, timeout=5) as r:
            r.read()
        return (time.perf_counter() - t) * 1000

    probe()
    samples = []
    for _ in range(5):
        try:
            samples.append(probe())
        except Exception:
            pass
    if not samples:
        raise RuntimeError("latency probe failed")
    return statistics.median(samples)


class Meter:
    def __init__(self):
        self.total = 0
        self.lock = threading.Lock()

    def add(self, n):
        with self.lock:
            self.total += n

    def read(self):
        with self.lock:
            return self.total


def download_worker(url, meter, stop):
    while not stop.is_set():
        try:
            req = urllib.request.Request(url, headers=dict(UA, **{"Accept-Encoding": "identity"}))
            with urllib.request.urlopen(req, timeout=8) as r:
                while not stop.is_set():
                    b = r.read(CHUNK)
                    if not b:
                        break
                    meter.add(len(b))
        except Exception:
            return


def upload_worker(url, meter, stop):
    parts = urllib.parse.urlsplit(url)
    path = parts.path + ("?" + parts.query if parts.query else "")
    zeros = bytes(CHUNK)
    while not stop.is_set():
        try:
            conn = http.client.HTTPSConnection(parts.netloc, timeout=8)
            conn.putrequest("POST", path)
            conn.putheader("Content-Type", "application/octet-stream")
            conn.putheader("Content-Length", str(PAYLOAD))
            conn.putheader("User-Agent", UA["User-Agent"])
            conn.endheaders()
            sent = 0
            while sent < PAYLOAD and not stop.is_set():
                conn.sock.sendall(zeros)
                sent += CHUNK
                meter.add(CHUNK)
            if stop.is_set():
                conn.close()
                return
            conn.getresponse().read()
            conn.close()
        except Exception:
            return


def run_phase(name, worker, urls, warm=1.5):
    meter = Meter()
    stop = threading.Event()
    threads = [threading.Thread(target=worker, args=(u, meter, stop), daemon=True) for u in urls]
    for t in threads:
        t.start()
    start = time.perf_counter()
    last_t, last_b = start, 0
    samples = []
    while True:
        time.sleep(0.2)
        now = time.perf_counter()
        elapsed = now - start
        b = meter.read()
        inst = (b - last_b) * 8 / max(now - last_t, 1e-6) / 1e6
        last_t, last_b = now, b
        if elapsed > warm:
            samples.append(inst)
        recent = samples[-5:] if samples else [inst]
        emit(phase=name, mbps=round(sum(recent) / len(recent), 2), pct=min(1.0, elapsed / PHASE_SECONDS))
        if elapsed >= PHASE_SECONDS:
            break
    stop.set()
    if not samples:
        raise RuntimeError(name + " produced no data")
    tail = samples[len(samples) // 3:]
    return round(sum(tail) / len(tail), 2)


def main():
    try:
        emit(phase="start")
        urls = get_targets()
        emit(phase="latency")
        ms = ping(urls[0])
        emit(phase="latency_done", ping=round(ms, 1))
        down = run_phase("download", download_worker, urls)
        emit(phase="download_done", mbps=down)
        up = None
        try:
            up = run_phase("upload", upload_worker, urls[:3])
        except Exception:
            up = None
        emit(phase="done", ping=round(ms, 1), down=down, up=up)
    except Exception as e:
        emit(phase="error", message=str(e) or e.__class__.__name__)


main()
