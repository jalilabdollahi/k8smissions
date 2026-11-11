# Module 10 fixtures

Shared by the levels of module 10 (operators). Levels use them from `setup.sh` and
`validate.sh` (`. ../_fixtures/lib.sh`); nothing is copied into a level folder. The
first-half author owns this directory; the second half may only use it. `solution.sh`
runs in an empty directory and cannot source `lib.sh`; it uses plain `kubectl`.

Nothing is simulated: controllers are stdlib Python in a ConfigMap run by
`python:3.12-alpine`; webhooks are real HTTPS servers the API server calls.

## Controller helper: `kapi.py`

`install_kapi` (in `lib.sh`) creates ConfigMap `kapi-lib` in `$NS`. Mount it at `/kapi` (never `/lib`: that hides the musl loader and python fails with "no such file")
and set `PYTHONPATH=/kapi`; the level's own script (a second ConfigMap, mounted at `/app`)
does `from kapi import api, patch, forever, log, NS`:

| name | meaning |
|---|---|
| `api(method, path, body=None, ctype="application/json")` | call the API with the pod's ServiceAccount token; returns `(status, dict)`; never raises on 4xx/5xx; connection errors return `(599, {...})` |
| `patch(path, body)` | merge-patch (`application/merge-patch+json`); use `.../status` for the status subresource |
| `forever(fn, every=2)` | run `fn` every `every` seconds forever; an exception is logged, not fatal |
| `log(...)` | timestamped line, flushed (what players read with `kubectl logs`) |
| `NS` | the pod's namespace |

The token file is re-read on every call. Level scripts hold the bug; `kapi.py` is only plumbing.
Pod snippet: image `python:3.12-alpine`, command `["python","-u","/app/controller.py"]`, env
`PYTHONPATH=/kapi`, volumes `kapi-lib` (/kapi) and the level's code ConfigMap (/app). The pod
needs a ServiceAccount, a Role and a RoleBinding from the level's `broken.yaml`.

## Webhook server: `server.py`

`install_webhook_server` creates ConfigMap `webhook-server` (mount at `/app`, command
`["python","-u","/app/server.py"]`). It serves HTTPS on 8443 and loads `/tls/tls.crt` and
`/tls/tls.key` **once at start** (a Secret swap needs a pod restart, on purpose). Its behaviour
is a handler module mounted at `/handler/handler.py` (ConfigMap key `handler.py`; override the
path with env `HANDLER`), which defines any of:

- `validate(request) -> (allowed, message)` served on `POST /validate`
- `mutate(request) -> (allowed, message, json_patch_ops)` on `POST /mutate`
- `convert(objects, desiredAPIVersion) -> objects` on `POST /convert` (raise `ValueError` to fail)

`request` is the AdmissionReview `request` (pod under `request["object"]`). The server logs one
line per call (`/validate CREATE ns/name -> allow|DENY message`), answers the review `apiVersion`
it was sent and returns 404 for other paths (visible in its log when a webhook has no `path`).
Handlers are written inline per level (a ConfigMap in `broken.yaml`) because the handler is
where the level's logic lives; `handlers/*.py` are small samples (`deny-latest`, `label-inject`,
`convert-passthrough`) usable with `install_handler`.

Service convention: Service `<name>` port 443 -> targetPort 8443, so the API server calls
`https://<name>.k8smissions.svc:443`. Use `readinessProbe.tcpSocket.port: 8443`.

## Certificates: `certs/` (committed, never regenerated at run time)

`gen-certs.sh` documents how they were made (OpenSSL 3.4+, ECDSA P-256, fixed dates; it is
not run by any level). Fixed dates mean results never change.

| dir | contents |
|---|---|
| `certs/ca-a/ca.crt` (+`ca.key`) | root CA, 2020-01-01 to 2120-01-01; signs every leaf below |
| `certs/ca-b/ca.crt` | unrelated root CA (key deleted): the "stale" CA bundle |
| `certs/good/` | `tls.crt`, `tls.key`; SANs `*.k8smissions.svc`, `*.k8smissions.svc.cluster.local`; valid 2020-2120 |
| `certs/expired/` | same names, valid 2020-01-01 to 2021-01-01 (always expired) |
| `certs/nosan/` | CN `webhook.k8smissions.svc` only, no SAN (Go refuses it; spiked on kind 1.36: `x509: certificate is not valid for any names, but wanted to match <svc>.<ns>.svc`, not the old "legacy Common Name" text) |
| `certs/good-labeler/` | like `good` but for `*.labeler-system.svc` (l11 "system" namespace) |

The wildcard covers any Service name in namespace `k8smissions`. The cert files hold no
secrets of value: they exist only for the game.

## `lib.sh` functions (all use `$NS`, default `k8smissions`)

`lab_ns [ns]` label a namespace `k8smissions/lab=true`; **every webhook configuration must
carry `namespaceSelector: {matchLabels: {k8smissions/lab: "true"}}`** so a broken webhook can
never touch `kube-system` (it matches only lab namespaces). `install_kapi`,
`install_webhook_server`, `install_handler <cm> <file>`, `tls_secret <name> <good|expired|nosan|good-labeler> [ns]`
(kubernetes.io/tls), `ca_secret <name> <ca-a|ca-b> [ns]` (Opaque with `ca.crt`),
`cabundle <ca-a|ca-b>` (one-line base64 for `caBundle`), `apply_managed` (apply stdin and label
`k8smissions/managed=true`; use it in `setup.sh` for CRDs/webhook configurations that must exist
before custom resources, because `setup.sh` runs before `broken.yaml`), `label_managed`,
`wait_crd <crd>`, `wait_rollout <deploy>`.

Pattern: `setup.sh` installs the helper ConfigMaps, secrets, the CRD (`apply_managed`), waits
for `Established` and creates the custom resources; `broken.yaml` holds the Deployments, RBAC,
the controller or handler code and anything the player should read. Probe objects made by a
validator are deleted by the validator; namespaced leftovers go with the namespace.
