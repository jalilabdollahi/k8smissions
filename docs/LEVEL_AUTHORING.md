# Writing a K8sMissions level

Every level teaches one real Kubernetes skill through a small, believable
incident. The player gets a broken cluster, investigates with `kubectl`, fixes
it, and `validate.sh` proves the fix. A level is done only when all three pass:

```bash
scripts/test_levels.py <module>/<level> --cluster <your-cluster> --mirror
scripts/lint_levels.py <module>/<level>
scripts/check_duplicates.py <module>/<level>
```

## Files

```
modules/<module>/<level-N-slug>/
  mission.yaml        JSON despite the extension (see below)
  broken.yaml         the broken state (and/or setup.sh)
  setup.sh            optional bash; runs before broken.yaml, cwd = level dir, $NS set
  validate.sh         bash; exit 0 = solved, exit 1 = not yet. cwd = level dir, $NS set
  solution.sh         bash; the reference fix, typed the way a player would
  hint-1.txt hint-2.txt hint-3.txt
  reveal.md           the full answer, shown on request for -50% XP
  debrief.md          shown after the level is solved
  common-mistakes.md  shown after the debrief
```

**Never rename or delete a level folder**: the folder name is the level id in
players' `progress.json`. The scenario you write must fit the slug
(`level-2-crashloop` stays about a crash loop) but everything inside the folder
is yours to rewrite. Delete stale files you replace (e.g. `solution.yaml`
once `solution.sh` exists).

## mission.yaml

```json
{
  "name": "Short title",
  "description": "The situation as the on-call engineer sees it: symptoms and impact.",
  "objective": "The end state that must be true, with exact resource names.",
  "xp": 150,
  "difficulty": "intermediate",
  "expected_time": "10m",
  "concepts": ["readinessProbe", "endpoints"],
  "module": "module-3-networking",
  "level": "level-5-networkpolicy",
  "requires": [],
  "settle_seconds": 15,
  "solve_timeout": 150,
  "cleanup": []
}
```

- `description`: symptoms, not causes. "Checkout returns 503 for about half of
  the requests since the 14:00 deploy." Never "the selector is wrong".
- `objective`: what must be true, not how. "`checkout` answers 200 on every
  request through Service `checkout`", not "fix the selector". Name the resources
  the validator checks. Don't name the field to change unless the level is
  about learning that field's syntax.
- `difficulty` / `xp`: beginner 100, intermediate 150, advanced 200, expert 300.
  - beginner: one symptom, one cause, found with `get`/`describe`/`logs`.
  - intermediate: the obvious first guess is wrong, or two related objects.
  - advanced: several objects, events and controller behaviour, a trap.
  - expert: a multi-cause incident; the player must find the causes and fix
    them in a sensible order.
- `requires`: add-ons from `engine/addons.py`: `metrics-server`,
  `ingress-nginx`, `tekton`, `argocd`. The engine installs them on demand.
- `settle_seconds`: how long the broken state needs to show its symptom
  (CrashLoopBackOff needs ~20s). The test waits this long before checking that
  the broken state fails.
- `solve_timeout`: how long after `solution.sh` the validator may take to pass.
- `cleanup`: objects the *player* is expected to create outside the
  `k8smissions` namespace, e.g. `["clusterrolebinding/ci-deployer"]`.

## The cluster

- `kind-config.yaml`: Kubernetes 1.36, one control plane, two workers
  (`k8smissions-worker`, `k8smissions-worker2` in the game; other names in test
  clusters, so never hard-code node names, look them up).
- Default namespace for everything is `k8smissions` (`$NS`). Extra namespaces
  are fine; they are deleted between levels if `broken.yaml` creates them.
- Everything created from `broken.yaml`/`setup.yaml` gets the label
  `k8smissions/managed=true` and is deleted before the next level, including
  cluster-scoped objects (CRDs, webhooks, ClusterRoles, PVs, PriorityClasses).
  Objects that `setup.sh` creates imperatively outside `$NS` must carry that
  label themselves.
- Node state is reset between levels: uncordoned, every taint except the
  control-plane one removed, every node label outside the `kubernetes.io` /
  `k8s.io` domains removed. So use labels like `disktype=ssd` or
  `zone=eu-1a` for level state, never `topology.kubernetes.io/zone`.
- Never modify objects that exist before the level (CoreDNS, kube-proxy,
  kindnet, add-on namespaces). If a scenario needs a broken DNS server, ingress
  or controller, deploy your own copy in `$NS`.
- Images: pinned tags only, no `:latest`, no untagged images; small images
  (busybox, alpine, nginx:*-alpine, python:3.12-alpine, curlimages/curl,
  hashicorp/http-echo, registry.k8s.io/pause). Check a tag exists with
  `docker manifest inspect <image>` before using it. An image that must not
  exist (ImagePullBackOff levels) goes on a line ending with `# lint: allow-image`.
- No custom-built images. A controller or "app with a bug" is a script in a
  ConfigMap run by a stock image (e.g. `python:3.12-alpine` with stdlib only,
  calling the API with the pod's service-account token).

## validate.sh

1. **No free passes.** It must fail on an empty namespace and on the broken
   state. End the script with `exit 1`; pass only through explicit checks.
2. **Check behaviour, not a field.** Prove the outcome the objective promises:
   pods Ready and not restarting over a short window, a Service actually
   answering through `curl` from a probe pod, a Job `Complete`, a PVC `Bound`
   and data still there, `kubectl auth can-i` returning yes (and no for what
   must stay forbidden). Check spec fields only when the field *is* the outcome
   (e.g. a securityContext policy).
3. **Accept every correct fix.** If the objective says "enough memory", accept
   any limit that works, not exactly `256Mi`. Don't require one specific way
   (patch vs edit vs delete-and-recreate).
4. **Can't be gamed by deleting things.** "No pod is crash-looping" passes if
   the Deployment is deleted, so also check the workload exists with the
   expected replicas and serves.
5. **Bounded and deterministic.** Finish within ~60s: use `kubectl wait
   --timeout`, `timeout 10 ...`, `curl --max-time`. No `sleep 60`.
6. **Messages.** Lines starting `✅` for passed checks and `❌` for what is
   still wrong, without giving the answer (`❌ checkout: 2 of 4 requests
   failed`). Several checks per level are good; print each.
7. Use `$NS`, never hard-coded node names. `set -u` is fine; avoid
   `set -e` around commands that are expected to fail.

## solution.sh

The reference fix as a player would type it at a terminal: `kubectl patch`,
`kubectl set`, `kubectl apply -f - <<'EOF'`, `kubectl rollout undo`,
`kubectl delete pod`, and so on. It runs in an empty temporary directory, so it
cannot read level files. It may wait for things to settle
(`kubectl rollout status`). If the level needs investigation to find a value
(a port, a key name), discover it with kubectl in the script as a player would,
rather than hard-coding the answer when it is randomised.

## Hints, reveal, debrief, common mistakes

- **hint-1**: where to look. An investigation command is fine
  (`kubectl describe pod ...`, `kubectl get events`), the fix is not.
- **hint-2**: the concept and the field or object involved, with a pointer to
  `kubectl explain <path>`.
- **hint-3**: close to the answer: the exact command shape with one detail for
  the player to fill in.
- **reveal.md**: the full fix with a one-line explanation per step.
- **debrief.md**: what was broken, the evidence that pointed to it, why
  Kubernetes behaved that way, the fix, how this differs in production, and
  two or three commands worth remembering. 150-400 words, written for this
  level only.
- **common-mistakes.md**: two or three mistakes a player is likely to make on
  *this* level, why each fails, and what to do instead.

Never generate any of these from a shared template or script. Each level's
files are written for that level; `scripts/check_duplicates.py` must report
nothing for your levels.

## Variety inside a module

Before writing, read the module's map in `docs/curriculum/<module>.md`. Each
level has its own scenario, its own failing mechanism and its own fix. If two
levels end with the same command (`kubectl scale`, raising a memory limit),
one of them is wrong. Realistic names (`checkout`, `ledger-api`,
`thumbnailer`), realistic numbers, and a trap where the difficulty calls for
one.

## Working in parallel

Each author (person or agent) uses their own test cluster
(`--cluster k8sm-<name>`), touches only the levels assigned to them, and does
not edit `engine/`, `scripts/`, `kind-config.yaml` or other modules. Report
anything those need instead. Don't commit; the maintainer commits per module.
