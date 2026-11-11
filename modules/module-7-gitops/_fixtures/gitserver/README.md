# In-cluster Git server (module 7, reused read-only by module 8)

One small Git server in namespace `gitops-git`, so Argo CD, Helm and Kustomize
levels have a real repository to read and a player can commit and push.
Owned by module 7; module 8 refers to it as `../../module-7-gitops/_fixtures/gitserver/`.

## What runs

- Deployment and Service `gitserver` (port 8080), namespace `gitops-git`, label
  `k8smissions/managed=true` on everything (the engine deletes the namespace between levels,
  so every level that needs Git starts it again from its `setup.sh`).
- Image `python:3.12-alpine` runs `server.py` (stdlib only, mounted from ConfigMap
  `gitserver-code`): the Git smart HTTP protocol, i.e. `git upload-pack` and
  `git receive-pack --stateless-rpc`. Clone, fetch and push all work.
- An init container from `alpine/git:2.49.1` copies the `git` binary into an emptyDir shared with the
  server container. Spike result: `alpine/git` has no BusyBox `httpd`, no `git-http-backend` and
  no `git-daemon`, so the map's "BusyBox httpd + http-backend" and "git daemon" plans cannot be built
  from it; this keeps the same URLs. Git is also on `PATH` in the container
  (`kubectl -n gitops-git exec -it deploy/gitserver -- sh`).
- Bare repos live in an emptyDir at `/srv/git/<name>.git` (lost if the pod restarts; `seed.sh` again).
  Default branch is `main`.

## URLs

| what | URL |
|------|-----|
| public repo (no auth) | `http://gitserver.gitops-git.svc.cluster.local:8080/cgi-bin/git/<name>.git` |
| private repo (basic auth) | `http://gitserver.gitops-git.svc.cluster.local:8080/cgi-bin/git/private/<name>.git` |

Private repos need user `ci-bot`, password `ci-bot-secret` (HTTP basic). Without credentials the
server answers 401. Argo CD needs no credentials for public repos.

## From a level's `setup.sh` (cwd is the level directory)

```bash
G=../_fixtures/gitserver                 # module 7;  module 8: ../../module-7-gitops/_fixtures/gitserver
$G/seed.sh ledger repo "initial import"  # NAME SRC_DIR [MESSAGE]: repo ledger.git = tree of ./repo, one commit on main
PRIVATE=1 $G/seed.sh shop-private repo   # same, under /private/ (module 8)
DELETE="old.yaml" $G/commit.sh ledger more-files "second commit"   # add or overwrite files, delete listed paths
$G/up.sh                                 # start the server only (seed.sh does this for you)
```

`seed.sh` replaces a repo of the same name. `commit.sh` appends one commit to an existing repo
(`PRIVATE=1` for private ones). Both go through `kubectl exec` into the pod, so they work
wherever the level's kubeconfig works and need no local port-forward.
Seeding takes about 20 seconds on a cold namespace (image pulls), 2 seconds afterwards.

## Player access

```bash
kubectl -n gitops-git port-forward svc/gitserver 8080:8080 &
git clone http://localhost:8080/cgi-bin/git/<name>.git
cd <name> && edit... && git commit -am "msg" && git push origin main
# private repo: git clone http://ci-bot:ci-bot-secret@localhost:8080/cgi-bin/git/private/<name>.git
```

With no local git, edit inside the pod instead:
`kubectl -n gitops-git exec -it deploy/gitserver -- sh` then `git clone /srv/git/<name>.git /tmp/w`,
change, commit, `git push origin main`.

A solution.sh does the same in its temporary directory (start the port-forward in the background
on a high port, `trap 'kill %1' EXIT`).

## Argo CD

Applications use `repoURL: http://gitserver.gitops-git.svc.cluster.local:8080/cgi-bin/git/<name>.git`.
Argo polls every 3 minutes; speed it up with
`kubectl annotate app NAME -n argocd argocd.argoproj.io/refresh=hard --overwrite`.

## Tested

Spiked on a kind 1.36 test cluster: seed, clone through port-forward, push, second clone, clone
without and with credentials on the private path, protocol v0 and v2 clones, a 3 MB push, and an
in-cluster clone from an `alpine/git:2.49.1` pod. Images pinned: `python:3.12-alpine`,
`alpine/git:2.49.1` (`docker manifest inspect` ok), `curlimages/curl:8.10.1` (probe).
