# Module 8 fixtures (owned by the first-half author, read-only for the second half)

Everything here is plain YAML or shell for stock images; nothing is built.

## Step images (pinned, all checked by running them in test levels)

| image | has | used for |
|-------|-----|----------|
| `busybox:1.36` | sh, wc, sha256sum, wget | ordinary steps |
| `alpine/kubectl:1.36.0` (94 MB) | sh, kubectl v1.36, sed, grep; runs as root | every step that calls `kubectl` (levels 8, 9, 11-14, 18) |
| `alpine/git:2.49.1` | git | clone steps |
| `curlimages/curl:8.10.1` | curl | probes, registry HTTP calls |
| `registry:2.8.3` | the registry itself | in-cluster registry, see `registry.sh` |
| `gcr.io/go-containerregistry/crane:debug@sha256:e78770b31258a3846f878036d9c1f63fbe4c871f9f56990bf77fd95c013e3c1b` | crane plus a busybox shell at `/busybox/sh` (script shebang `#!/busybox/sh`), root | push steps (levels 7, 17, 18); the only tag with a shell is the moving `debug`, so it is pinned by digest |

Rejected for kubectl steps: `registry.k8s.io/kubectl` and `rancher/kubectl` (no shell at all),
`alpine/k8s` (1.2 GB, a cold pull per node is too slow for a 45 s run budget).

## Git

Use `../../module-7-gitops/_fixtures/gitserver/` read-only from `setup.sh`
(`PRIVATE=1 .../seed.sh NAME DIR` for the `ci-bot` / `ci-bot-secret` area).
In-cluster URL: `http://gitserver.gitops-git.svc.cluster.local:8080/cgi-bin/git/private/NAME.git`.

## Registry

`registry.sh [USER:BCRYPT]` (run from a level's `setup.sh`, `$NS` set) creates Deployment and Service
`registry` (port 5000, plain HTTP, emptyDir storage) and waits until it is ready; with an htpasswd
line it turns on basic auth (Secret `registry-htpasswd`). Level 7 uses `ci-push` / `ship-it-4711`
with the bcrypt line in its `setup.sh`.

Push step recipe (verified in level 7): a `busybox` step writes `/workspace/layer.tar.gz`, then the crane
step runs `crane append --insecure -f /workspace/layer.tar.gz -t HOST:5000/REPO:TAG` (no base image, so
nothing is pulled from the internet). It prints `HOST/REPO@sha256:...` on stdout, so a result needs
`${out##*@}`. Set `env DOCKER_CONFIG=/tekton/creds/.docker` so crane reads the config Tekton writes for the
ServiceAccount's `kubernetes.io/dockerconfigjson` Secrets (no annotation needed for that type). Read back with
`curl -u user:pass -I -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' http://registry:5000/v2/REPO/manifests/TAG`
(`Docker-Content-Digest`).

## Things learned about Tekton v1.18 (kind 1.36)

- `broken.yaml` is applied without a namespace flag: every object needs `metadata.namespace: k8smissions`
  (except Namespaces).
- A step's exit code path is `$(steps.step-NAME.exitCode.path)`: the `step-` prefix is required, and an
  unknown reference is not substituted and not rejected (the shell just says "not found").
- Git credentials (`tekton.dev/git-N`) work with `alpine/git` without setting HOME.
- A `finally` Task referencing `$(tasks.X.results.R)` when X failed before writing `R` never starts and the
  PipelineRun stays `Running` (status Unknown); results written before the failure are still available.
- Param validation reasons: `ParameterMissing`, `ParameterTypeMismatch`, `InvalidWorkspaceBindings` (Pipelines run
  these checks at reconcile, so the PipelineRun object is created and then fails at once).
