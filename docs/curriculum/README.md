# K8sMissions curriculum

200 levels in 12 modules. Folder names (slugs) are fixed because they are the
level ids in players' `progress.json`; everything inside a level is rewritten
by hand. Each module has a map, `docs/curriculum/<module>.md`, written before
its levels: one row per level, so overlaps are caught on paper first.

Read `docs/LEVEL_AUTHORING.md` before writing a map or a level.

## Map format

A short intro paragraph: what the module teaches, which add-ons it uses, and
the overlap decisions with other modules ("module 6 owns probe tuning, so the
probe levels here are about ..."). Then this table, one row per existing slug,
in order:

| # | slug | difficulty | scenario | skills / commands | validator checks | trap or twist |
|---|------|-----------|----------|-------------------|------------------|---------------|

- **scenario**: the incident as the player meets it, with realistic names and
  numbers. Two or three sentences.
- **skills / commands**: what the player has to use and understand.
- **validator checks**: the behaviour `validate.sh` proves (see the authoring
  guide: behaviour over fields, accept every correct fix, can't be gamed by
  deleting things).
- **trap or twist**: what makes the obvious first guess wrong, sized to the
  difficulty (beginner levels may have none).

End with a **Notes** section: shared fixtures, images, add-ons, and every slug
whose literal topic can't be done for real on kind (see below).

## Slugs that can't be done literally

Some slugs name things a local kind cluster can't safely provide (a real
etcd quota, a node clock, OLM, a cloud load balancer, a service mesh). Keep
the *theme* of the slug and build a real, working scenario for it, and write
the reasoning in Notes. Examples of acceptable reinterpretations:

- `etcd-quota`, `etcd-pressure`: object-count pressure the player can see
  (`count/configmaps` ResourceQuota, thousands of stale Events/ConfigMaps
  from a runaway job, oversized objects rejected by the API server's size
  limit), never a ConfigMap that pretends to be etcd.
- `clock-skew`: two services in pods that disagree about time through
  configuration (token lifetime vs leeway, a CronJob `timeZone`), proven by
  behaviour.
- `olm-subscription`: an operator installed from plain manifests whose
  "subscription" (channel, version pin, CRD install order) is wrong.
- `loadbalancer`: a `LoadBalancer` Service on kind stays `<pending>`; the
  level teaches why and what to use instead, verified through a real path.
- `service-mesh-timeout`: an Envoy sidecar (stock `envoyproxy/envoy` image
  with a ConfigMap config) with a route timeout shorter than the backend's
  latency.
- `vpa-off`: right-sizing requests from observed usage (`kubectl top`,
  metrics-server) when no VPA is installed.

Never "fix" a level by flipping a flag in a ConfigMap that only the validator
reads. If it can't be real, change the scenario until it is.

## Module scopes

| module | levels | difficulty | owns | add-ons |
|---|---|---|---|---|
| 1 foundations | 20 | beginner | first contact: pods, crash/pull/pending basics, env, ConfigMap/Secret consumption, labels, Service basics, init/sidecar containers, DaemonSet/Job/CronJob basics, LimitRange, finalizers | – |
| 2 workloads | 15 | beginner → intermediate | Deployment mechanics: replicas, rollout/rollback/pause, maxSurge/maxUnavailable, basic probes, basic HPA, PDB on drain, blue-green and canary with plain Services, StatefulSet identity, ReplicaSet ownership, CronJob concurrency | metrics-server |
| 3 networking | 15 | intermediate | Services in depth (selectors, named ports, endpoints/EndpointSlices, headless, NodePort, externalTrafficPolicy, session affinity, multi-port), DNS, Ingress, NetworkPolicy ingress and egress | ingress-nginx |
| 4 storage | 15 | intermediate | PV/PVC binding, StorageClass, access modes, reclaim policies, StatefulSet volumes, permissions/fsGroup, emptyDir, ConfigMap/Secret volumes and projection | – |
| 5 security | 15 | intermediate → advanced | RBAC (Role, ClusterRole, aggregation, ServiceAccounts), securityContext, capabilities, Pod Security Admission, ResourceQuota as a guardrail, NetworkPolicy as isolation, node affinity/taints as workload isolation, PriorityClass for critical pods | – |
| 6 observability | 15 | intermediate → advanced | finding evidence: events, logs (previous, multi-container), `kubectl top`, exit codes and restart reasons, probe design and tuning, ephemeral debug containers, node conditions, log levels, scrape annotations checked against a real scraper | metrics-server |
| 7 gitops | 15 | advanced | Helm (values, rollback, templates), Kustomize (overlays, patches), Argo CD (sync, self-heal, drift), GitOps vs HPA conflicts, graceful shutdown in deploys, secrets in GitOps, stuck namespace cleanup | argocd |
| 8 cicd | 18 | advanced | Tekton Tasks/Pipelines/runs: params, workspaces, results, finally, sidecars, auth secrets, RBAC for pipeline SAs, triggers, deploy gates, canary/rollback steps done with kubectl from a pipeline | tekton |
| 9 scheduling | 18 | advanced | the scheduler: taints/tolerations with effects, affinity/anti-affinity, topology spread, priority and preemption, requests vs allocatable, extended resources, scheduler names, init-container resource math, DRA-style resource requests, deadlocks | metrics-server |
| 10 operators | 18 | expert | CRDs (schema, validation, versions, conversion, status subresource, categories, storage versions), controllers written as small scripts (reconcile loops, leader election, RBAC, finalizers, ownerReferences, generation/observedGeneration), admission webhooks (certs, selectors, timeouts, failure policy) | – |
| 11 performance | 18 | expert | performance and SRE: CPU throttling, memory sizing, DNS ndots cost, connection limits, readiness gates, PDBs vs upgrades, timeouts, rollout speed, quota pressure, policy cost, SLOs measured by a real probe | metrics-server |
| 12 wargames | 18 | expert | multi-cause incidents that combine earlier modules; each has 2–4 real faults, a misleading symptom, and a validator that checks every fault and the user-facing outcome | any |

## Ownership of repeated topics

The old levels repeated the same mechanical fix under different stories. Each
repeated topic below is owned once per angle; maps must stay inside their
angle.

| topic | owner and angle |
|---|---|
| OOMKilled | m1 l13 recognise OOMKilled and size the limit; m6 l6 tell OOM apart from app exit and liveness kill using evidence; m11 l12 a leak vs a too-small limit (growth over time); m12 l11 an OOM storm with a second cause |
| replicas / scaling | m2 l1 replica count and why pods don't appear (quota or selector); m2 l5 basic HPA; m11 l2 HPA without metrics; m7 l11 an invalid HPA from Git; m7 l8 GitOps fighting the HPA over `replicas` |
| PodDisruptionBudget | m2 l7 PDB blocks a drain; m5 l7 PDB protecting a critical quorum service; m11 l7 too-strict PDB stalls node upgrades; m12 l5 drain in production with several blockers |
| RBAC | m5 l1 Role basics; m5 l11 in-cluster app's SA; m5 l15 aggregated ClusterRoles; m8 l8 pipeline SA deploying cross-namespace; m8 l14 pipeline SA creating runs; m10 l8 controller RBAC incl. status; m12 l13 lockout after rotation |
| probes | m2 l3 liveness kills a healthy app; m2 l4 readiness keeps traffic away; m6 l5 choosing exec/tcp/http/grpc; m6 l8 timeouts under load; m6 l11 wrong readiness path; m6 l12 failureThreshold math; m6 l13 startupProbe; m11 l6 readinessGates |
| graceful shutdown | m7 l6 dropped requests during a GitOps rollout (preStop + endpoints delay); m11 l11 long-running work killed by a short grace period / SIGTERM ignored |
| Service wiring | m1 l7 Deployment selector vs template labels; m1 l8 port vs containerPort; m3 l1 a selector that also catches other pods; m3 l11 named targetPort after a container port rename; m3 l8 endpoints empty because pods aren't Ready; m3 l15 multi-port naming |
| memory/CPU requests | m1 l4 Pending from requests; m9 l8 fit across nodes; m9 l10 allocatable vs capacity; m9 l17 balloon pods/overprovisioning; m11 l4 CPU throttling |
| config | m1 l9 ConfigMap env basics; m4 l6 missing key in a volume; m4 l13 projection items; m3/m11 DNS config; m12 l3 config storm |
