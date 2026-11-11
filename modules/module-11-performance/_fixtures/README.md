# Module 11 fixtures

Shared by the performance levels. Read-only for anyone but the module 11 first-half author.
Everything here is stdlib Python (`python:3.12-alpine`) or plain bash; no custom images.

## lib.sh

`. ../_fixtures/lib.sh` from a level's `validate.sh` or `setup.sh` (cwd is the level directory).
Needs `kubectl` and `jq`; `$NS` defaults to `k8smissions`.

| function | what it does |
|---|---|
| `ok` / `bad` | print a line starting with a check or cross mark |
| `cpu_to_m`, `mem_to_mi` | quantity strings to millicores / Mi |
| `ready_count <sel>`, `wait_ready <sel> <n> [secs]` | Ready, non-terminating pods matching a label selector |
| `live_pods <sel>` | names of Running, non-terminating pods (kubectl jsonpath cannot filter on `deletionTimestamp==null`) |
| `restart_sum <sel>` | total container restarts |
| `cgroup_cpu <pod> [ctr]` | `nr_periods nr_throttled throttled_usec` from `/sys/fs/cgroup/cpu.stat` (cgroup v2). `0 0 0` when the container has no CPU limit |
| `cgroup_mem_mi <pod> [ctr]` | `memory.current` of the container's cgroup, in Mi |
| `run_probe <url> <rate> <conc> <secs> [K=V...]` | runs `probe.py` in a throwaway pod, waits, prints its final JSON line (see below) |
| `start_load <name> <url> <rate> <conc> [K=V...]` | starts (once) a never-ending probe pod, used to keep load on a Deployment |

## probe.py

Load generator and latency probe: `URL`, `RATE` (req/s), `CONC` (threads), `DURATION` (0 = forever),
`WINDOW`, `TIMEOUT`, `RETRY` (1 = one retry after a failure), `HOSTHDR`. Prints one JSON line per
window and, for finite runs, a last line with `"final": true`:

    {"t": 1731300000, "count": 600, "errors": 0, "p50_ms": 11, "p95_ms": 24, "max_ms": 61, "codes": {"200": 600}}

An error is an exception (timeout, reset, refused) or a non-2xx status. Requests are paced per thread;
a slow target does not make the probe burst to catch up. `run_probe` and `start_load` ship the script in
a ConfigMap `probe-script` (created from this file) and mount it at `/probe`. Levels with a standing client for the player to read (l2, l4) carry a small inline script in `broken.yaml` instead.

## Measured behaviours (spiked on a kind 1.36 test cluster)

* **cgroup v2 files** are readable through `kubectl exec` in every container that has `cat`: `cpu.stat`
  contains `nr_periods`/`nr_throttled`/`throttled_usec` only when the container has a CPU limit.
* **CPU-bound load without a calibration step**: burn until `time.thread_time()` advances N ms. It counts CPU
  time, not wall time, so throttling stretches latency exactly as it would for real work.
* **Own CoreDNS copy** (`registry.k8s.io/coredns/coredns:v1.14.2`, already on the nodes, no shell):
  one server block per zone. A catch-all `.:53 { log; template ANY ANY { rcode NXDOMAIN } }` plus
  `payments.internal:53 { log; hosts { 10.20.30.40 name } }`. Do **not** put `hosts` + `fallthrough` before
  the `template` in one block: `template` runs first and answers NXDOMAIN for real names. The `log` plugin
  prints one line per query: `... "A IN name. udp 42 false 512" NXDOMAIN ...`; count lines with `grep -c`.
  A `file` zone (`svc.cluster.local`) gives proper NXDOMAIN for unknown names in its zone.
  Clients use `dnsPolicy: None` with `dnsConfig` pointing at the copy's Service ClusterIP (module 11 l3
  pins `10.96.150.53` in `broken.yaml`).
* **musl resolver** (`python:3.12-alpine`): `socket.getaddrinfo(name, None, AF_INET)` sends one A query per
  candidate name and honours `ndots` and `search`. With `ndots:5` and 3 search domains, a 2-dot name costs
  4 queries; with `ndots:2` or a trailing dot it costs 1.
* **Envoy** (`envoyproxy/envoy:v1.31.2`, no curl in the image): static config from a ConfigMap; admin on
  `0.0.0.0:9901` is reachable from a sibling container at `127.0.0.1:9901`. Counter names:
  `cluster.<name>.upstream_rq_timeout`, `cluster.<name>.upstream_rq_504`, `cluster.<name>.upstream_rq_total`.
  `route.timeout` expiring gives a 504 with response flag `UT` in the stdout access log. Static config is
  read at start: editing the ConfigMap changes nothing until the container restarts.
* **Eviction without `kubectl drain`**: `kubectl create --raw /api/v1/namespaces/$NS/pods/<p>/eviction -f -`
  with a `policy/v1 Eviction` body honours PodDisruptionBudgets (HTTP 429 when refused). Used in l7 so a
  validator drains only its own namespace and never evicts kube-system pods.
* A `ResourceQuota` with `count/configmaps` counts `kube-root-ca.crt` too.
* Do not create test namespaces on the shared pool clusters: the other authors' cleanup deletes them.
