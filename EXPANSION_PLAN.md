# K8sMissions — Expansion Plan: 75 → 200 Levels

## Summary
- Current: 7 modules, 75 levels, ~19,000 XP
- Target:  12 modules, 200 levels, ~52,000 XP
- Strategy: +5 levels to each existing module (7×5=35) + 5 brand-new modules ×18 levels (5×18=90)
- Total new: 35 + 90 = 125 new levels → 75 + 125 = 200 levels

---

## Status

| Section | Modules | Status |
|---------|--------|--------|
| Phase 1 | Module 1 extensions (levels 16-20) | ✅ DONE |
| Phase 2 | Module 2 extensions (levels 11-15) | ✅ DONE |
| Phase 3 | Module 3 extensions (levels 11-15) | ✅ DONE |
| Phase 4 | Module 4 extensions (levels 11-15) | ✅ DONE |
| Phase 5 | Module 5 extensions (levels 11-15) | ✅ DONE |
| Phase 6 | Module 6 extensions (levels 11-15) | ✅ DONE |
| Phase 7 | Module 7 extensions (levels 11-15) | ✅ DONE |
| Phase 8 | Module 8: CI/CD & Pipelines (18 levels) | ✅ DONE |
| Phase 9 | Module 9: Advanced Scheduling (18 levels) | ✅ DONE |
| Phase 10 | Module 10: Custom Resources & Operators (18 levels) | ✅ DONE |
| Phase 11 | Module 11: Performance & SRE (18 levels) | ✅ DONE |
| Phase 12 | Module 12: Production War Games (18 levels) | ✅ DONE |
| Phase 13 | Update ui.py XP totals + module titles | ✅ DONE |
| Phase 14 | Update welcome screen (200 levels, new XP total) | ✅ DONE |

---

## Phase 1 — Module 1 Extensions (levels 16–20)
Directory: `modules/module-1-foundations/`
XP per level: 150–200 (harder than earlier levels)

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 16 | level-16-daemonset | The Everywhere Pod | DaemonSet exists but pods stuck Pending due to missing toleration for control-plane taint | Add toleration for node-role.kubernetes.io/control-plane |
| 17 | level-17-job-completion | One-Shot Task | Job fails repeatedly — completions:1 but backoffLimit:0, pod command exits 1 | Fix the command so the job exits 0 |
| 18 | level-18-cronjob-suspend | Suspended Schedule | CronJob is suspended:true and never fires | Set suspend: false |
| 19 | level-19-resource-limits-missing | The Noisy Neighbour | Pod has requests but no limits — LimitRange in namespace rejects it | Add matching limits to satisfy LimitRange |
| 20 | level-20-finalizer-stuck | The Undeletable Object | Namespace stuck in Terminating forever — ConfigMap has a custom finalizer that was never cleared | Patch the object to remove the finalizer |

---

## Phase 2 — Module 2 Extensions (levels 11–15)
Directory: `modules/module-2-workloads/`

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 11 | level-11-deployment-pause | Frozen Rollout | Deployment is paused — pods stuck on old image | Resume the deployment |
| 12 | level-12-cronjob-overlap | Concurrent Chaos | CronJob fires every minute with concurrencyPolicy:Allow — hundreds of pods piling up | Change concurrencyPolicy to Forbid or Replace |
| 13 | level-13-replicaset-orphan | Abandoned Pods | Deployment deleted but ReplicaSet + pods remain because ownerReferences were stripped | Delete the orphaned ReplicaSet |
| 14 | level-14-maxsurge-zero | Zero Surge | Deployment rollingUpdate has maxSurge:0 and maxUnavailable:0 — update completely blocked | Set maxSurge to at least 1 |
| 15 | level-15-statefulset-headless | Headless Required | StatefulSet update stuck — serviceName points to a service that has ClusterIP instead of None | Change service to headless (clusterIP: None) |

---

## Phase 3 — Module 3 Extensions (levels 11–15)
Directory: `modules/module-3-networking/`

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 11 | level-11-dual-stack | IPv6 Surprise | Service configured for IPv6 only but node is IPv4 — ClusterIP assignment fails | Remove ipFamilies override or set to IPv4 |
| 12 | level-12-externalname | Alias Broken | ExternalName service points to wrong external hostname | Fix the externalName field |
| 13 | level-13-ingress-tls | TLS Mismatch | Ingress TLS secret name doesn't match the secret that exists | Update secretName to match existing secret |
| 14 | level-14-service-topology | Topology Miss | Topology-aware hints misconfigured — traffic never routes to local zone pods | Fix topologyKeys or remove the broken annotation |
| 15 | level-15-endpointslice | Slice Out of Sync | Manual EndpointSlice has wrong port — connections fail even though IPs are right | Fix the port in the EndpointSlice |

---

## Phase 4 — Module 4 Extensions (levels 11–15)
Directory: `modules/module-4-storage/`

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 11 | level-11-volume-snapshot | Snapshot Miss | VolumeSnapshot references a non-existent VolumeSnapshotClass | Create the VolumeSnapshotClass or fix the reference |
| 12 | level-12-subpath-mount | SubPath Headache | volumeMount uses subPath pointing to a directory that doesn't exist in the ConfigMap | Fix the subPath key name |
| 13 | level-13-projected-volume | Mixed Sources | Projected volume combines Secret and ConfigMap but Secret key name is wrong | Fix the key in the projected volume source |
| 14 | level-14-pvc-resize | Stuck Expansion | PVC resize requested but StorageClass has allowVolumeExpansion:false | Patch the StorageClass to enable expansion, then resize |
| 15 | level-15-hostpath-danger | Wrong HostPath | Pod mounts hostPath /etc/passwd into container — should use a safe emptyDir instead | Replace hostPath with emptyDir |

---

## Phase 5 — Module 5 Extensions (levels 11–15)
Directory: `modules/module-5-security/`

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 11 | level-11-image-policy | Blocked Image | AdmissionWebhook rejects images from Docker Hub — only gcr.io allowed | Change image to a gcr.io mirror |
| 12 | level-12-audit-log | Silent Audit | Audit policy is set to None for all requests — security team needs API activity logged | Set audit level to Metadata for the relevant verbs |
| 13 | level-13-falco-alert | Runtime Threat | Falco-simulated: pod runs a shell inside a container in production namespace — detect and kill it | Delete the offending pod and add a NetworkPolicy to block exec |
| 14 | level-14-secret-rotation | Expired Secret | TLS secret has certificate that expired — app returns SSL errors | Replace the TLS secret with a renewed certificate |
| 15 | level-15-opa-violation | Policy Denied | OPA Gatekeeper rejects pod — ConstraintTemplate requires runAsNonRoot, pod violates it | Fix the securityContext to pass the constraint |

---

## Phase 6 — Module 6 Extensions (levels 11–15)
Directory: `modules/module-6-observability/`

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 11 | level-11-prometheus-scrape | Blind Metrics | Prometheus ServiceMonitor exists but scraping nothing — port name mismatch | Fix the ServiceMonitor portName to match the Service |
| 12 | level-12-alert-silence | Sleeping Alert | AlertManager rule fires but all alerts are silenced by a catch-all matcher | Remove or narrow the silence matcher |
| 13 | level-13-log-format | Unreadable Logs | App writes JSON logs but log aggregator parses as plaintext — timestamps wrong | Add annotation to tell aggregator to parse as JSON |
| 14 | level-14-tracing-missing | No Spans | App has tracing disabled via env var — distributed trace shows no spans | Set OTEL_SDK_DISABLED=false |
| 15 | level-15-slo-breach | SLO on Fire | Error rate above SLO threshold — track down the deployment causing elevated 5xx | Find the bad deployment from metrics and roll it back |

---

## Phase 7 — Module 7 Extensions (levels 11–15)
Directory: `modules/module-7-gitops/`

| # | Folder | Name | Broken State | Fix |
|---|--------|------|-------------|-----|
| 11 | level-11-helm-dependency | Missing Chart | Helm chart has a dependency on a subchart that wasn't fetched | Run helm dependency update or add the dependency |
| 12 | level-12-argocd-ignorediff | Ignored Drift | ArgoCD ignoreDifferences is hiding a live mutation — cluster drifts silently | Remove the ignoreDifferences rule and fix the live resource |
| 13 | level-13-kustomize-nameprefix | Prefix Collision | Kustomize namePrefix causes duplicate names — two resources collide | Fix the namePrefix or rename the resource |
| 14 | level-14-flux-suspend | Flux Frozen | Flux Kustomization is suspended — cluster never reconciles | Set suspended: false |
| 15 | level-15-drift-detection | Silent Drift | Manual kubectl edit bypassed GitOps — cluster differs from git; detect and remediate | Revert the live change to match the Git state |

---

## Phase 8 — Module 8: CI/CD & Pipelines (18 levels)
Directory: `modules/module-8-cicd/`
Theme: Tekton, GitHub Actions proxies, pipeline failures, rollout gates

| # | Folder | Name | Key Concept |
|---|--------|------|-------------|
| 1 | level-1-pipeline-fail | Broken Stage | Tekton Task fails — wrong image |
| 2 | level-2-workspace-missing | No Workspace | Pipeline workspace not bound |
| 3 | level-3-param-default | Missing Param | Required param has no default and none passed |
| 4 | level-4-git-clone-auth | Clone Fails | Git clone Task missing SSH secret |
| 5 | level-5-build-cache | Slow Build | Build cache PVC not mounted |
| 6 | level-6-test-gate | Failing Gate | Test Task exit code blocks pipeline |
| 7 | level-7-image-push | Push Denied | Registry credentials missing in Task |
| 8 | level-8-deploy-task | Deploy Fails | kubectl Task missing RBAC |
| 9 | level-9-finally-task | Cleanup Skipped | Finally task not running on failure |
| 10 | level-10-trigger-binding | Event Ignored | TriggerBinding field name mismatch |
| 11 | level-11-canary-gate | Traffic Frozen | Canary analysis never promoted |
| 12 | level-12-rollout-abort | Manual Abort | Rollout aborted — need to resume or retarget |
| 13 | level-13-approval-gate | Waiting Forever | Manual approval step never unblocked |
| 14 | level-14-pipeline-rbac | Blocked Runner | Pipeline ServiceAccount lacks Role |
| 15 | level-15-concurrent-runs | Race Condition | Multiple pipeline runs corrupt shared PVC |
| 16 | level-16-sidecar-injector | Injector Blocks | Webhook sidecar injection prevents pipeline pod from starting |
| 17 | level-17-artifact-store | Lost Artifact | TaskRun output not accessible to next Task |
| 18 | level-18-multi-stage-finale | Full Pipeline Down | All pipeline stages broken simultaneously |

---

## Phase 9 — Module 9: Advanced Scheduling (18 levels)
Directory: `modules/module-9-scheduling/`
Theme: Taints, topology spread, resource classes, GPU, spot eviction

| # | Folder | Name | Key Concept |
|---|--------|------|-------------|
| 1 | level-1-taint-effect | Wrong Effect | NoExecute taint added mid-run evicts running pods |
| 2 | level-2-topology-spread | Unbalanced | TopologySpreadConstraint maxSkew:1 can't be satisfied |
| 3 | level-3-pod-affinity | Chicken-Egg | podAffinity requires a pod that isn't running yet |
| 4 | level-4-anti-affinity | Over-Constrained | podAntiAffinity on single-node cluster — nothing can schedule |
| 5 | level-5-preemption | Priority Order | Low-priority pod blocks critical pod — wrong priorityClass |
| 6 | level-6-spot-eviction | Spot Node Gone | Spot instance evicted — pod not rescheduling (no toleration) |
| 7 | level-7-gpu-resource | GPU Request | Pod requests nvidia.com/gpu but device plugin not found |
| 8 | level-8-numa-topology | NUMA Mismatch | CPU Manager policy mismatch causes resource allocation failure |
| 9 | level-9-descheduler | Hotspot Node | One node holds all pods — Descheduler not rebalancing |
| 10 | level-10-bin-packing | Fragmented | Bin packing disabled — wasting node capacity |
| 11 | level-11-extended-resource | Custom Resource | Pod requests a custom extended resource with wrong name |
| 12 | level-12-scheduler-profile | Wrong Profile | Custom scheduler profile not selected for workload |
| 13 | level-13-waiting-forever | Unschedulable Loop | Scheduler plugin error keeps pod in Pending |
| 14 | level-14-node-allocatable | Real Capacity | Node allocatable != Node capacity due to reserved resources |
| 15 | level-15-cgroup-v2 | cgroup Mismatch | Container runtime expects cgroup v1 on v2 node |
| 16 | level-16-resource-class | Class Denied | ResourceClaim references missing ResourceClass |
| 17 | level-17-balloon-pod | Reserved Space | Balloon pod holding capacity — need to evict it first |
| 18 | level-18-scheduling-finale | Cluster Can't Fit | Multiple scheduling constraints all active simultaneously |

---

## Phase 10 — Module 10: Custom Resources & Operators (18 levels)
Directory: `modules/module-10-operators/`
Theme: CRDs, controllers, admission webhooks, Helm operators

| # | Folder | Name | Key Concept |
|---|--------|------|-------------|
| 1 | level-1-crd-missing | Unknown Kind | kubectl apply fails — CRD not installed |
| 2 | level-2-crd-validation | Schema Rejected | CR violates CRD OpenAPI schema |
| 3 | level-3-controller-crash | Operator Down | Controller pod crashing — check logs |
| 4 | level-4-reconcile-loop | Infinite Loop | Controller stuck reconciling — status never converges |
| 5 | level-5-finalizer-leak | Stuck CR | CR stuck Terminating — operator not removing finalizer |
| 6 | level-6-webhook-timeout | Webhook Slow | ValidatingWebhook times out — pod creation blocked |
| 7 | level-7-webhook-cert | Cert Expired | Webhook TLS cert expired — all mutations rejected |
| 8 | level-8-rbac-operator | Operator Blind | Operator pod missing ClusterRole for the CR it manages |
| 9 | level-9-version-mismatch | API Version | CR uses v1alpha1 but operator only handles v1beta1 |
| 10 | level-10-conversion-webhook | Conversion Fail | Hub version conversion webhook broken — old CRs unreadable |
| 11 | level-11-owner-reference | Orphan Resource | Controller creates child resource with wrong ownerReference |
| 12 | level-12-status-subresource | Status Ignored | Controller updates spec instead of status — conflict errors |
| 13 | level-13-leader-election | Split Brain | Two operator instances both think they are leader |
| 14 | level-14-crd-upgrade | Breaking Change | CRD schema upgraded removing a required field — existing CRs invalid |
| 15 | level-15-helm-operator | Chart Drift | Helm operator managing chart but values ConfigMap changed — not reconciled |
| 16 | level-16-watch-filter | Watching Everything | Controller watches all namespaces — performance disaster |
| 17 | level-17-backoff-storm | Retry Flood | Controller requeues errors at full speed — CPU spike |
| 18 | level-18-operator-finale | Operator Meltdown | CRD missing + webhook expired + operator crashed + finalizer stuck |

---

## Phase 11 — Module 11: Performance & SRE (18 levels)
Directory: `modules/module-11-performance/`
Theme: Latency, VPA, resource tuning, chaos, load testing

| # | Folder | Name | Key Concept |
|---|--------|------|-------------|
| 1 | level-1-slow-startup | Slow Init | App takes 2 min to start — no startup probe |
| 2 | level-2-cpu-throttle | Throttled App | CPU limit too low — app latency spikes |
| 3 | level-3-memory-leak | Growing Memory | App has memory leak — no VPA, limit too low |
| 4 | level-4-vpa-conflict | VPA vs HPA | VPA and HPA both active on same Deployment — conflict |
| 5 | level-5-io-bound | Disk Saturation | IO-bound workload on same node as latency-critical app |
| 6 | level-6-gc-pressure | GC Pauses | JVM app has too small heap — GC pauses cause timeout |
| 7 | level-7-connection-pool | Pool Exhausted | DB connection pool too small — requests queue and timeout |
| 8 | level-8-dns-slowness | DNS Latency | ndots:5 causing excessive DNS lookups — fix resolv.conf |
| 9 | level-9-http2-grpc | Protocol Mismatch | gRPC service behind HTTP/1.1 proxy — connections broken |
| 10 | level-10-keep-alive | Short Connections | HTTP keep-alive disabled — connection overhead dominates |
| 11 | level-11-burst-credit | CPU Credits | Burstable QoS pod consumed CPU credits — throttled |
| 12 | level-12-network-bandwidth | Bandwidth Cap | Network bandwidth annotation limits pod throughput |
| 13 | level-13-hugepages | HugePages Missing | App needs HugePages but node has none allocated |
| 14 | level-14-sysctls | Kernel Param | App needs net.core.somaxconn tuned — not set |
| 15 | level-15-chaos-latency | Injected Latency | tc netem injecting 500ms latency — find and remove |
| 16 | level-16-pod-disruption | Rolling Pressure | Too-aggressive HPA scales to zero under load |
| 17 | level-17-ebpf-tracing | No Visibility | BPF-based tracer not loading — kernel version mismatch |
| 18 | level-18-performance-finale | Everything Slow | CPU throttle + DNS latency + probe tuning all active |

---

## Phase 12 — Module 12: Production War Games (18 levels)
Directory: `modules/module-12-wargames/`
Theme: Multi-failure scenarios, incident response, chaos drills, full-stack breakage

| # | Folder | Name | Scenario |
|---|--------|------|----------|
| 1 | level-1-database-failover | DB Down | Primary DB pod deleted — app can't reconnect to replica |
| 2 | level-2-cascading-failure | Domino | One microservice down causes all others to time out |
| 3 | level-3-config-storm | Bad Config | ConfigMap rollout corrupts 10 pods simultaneously |
| 4 | level-4-secret-deleted | Credential Void | Secret deleted while pods are running — all crash |
| 5 | level-5-node-drain-prod | Surprise Drain | Node drained mid-deployment — PDB too strict, drain fails |
| 6 | level-6-etcd-full | etcd Pressure | etcd size near limit — large objects need pruning |
| 7 | level-7-api-server-slow | Control Plane | API server slow — identify which resource floods the audit log |
| 8 | level-8-image-registry-down | Registry Gone | Internal registry unreachable — all new pods stuck ImagePullBackOff |
| 9 | level-9-cert-rotation | Mass Expiry | All cluster TLS certs expired — partial functionality only |
| 10 | level-10-clock-skew | Time Drift | Node clock skew — JWT tokens rejected cluster-wide |
| 11 | level-11-oom-storm | Memory Wave | Multiple OOMKilled pods cascade across a namespace |
| 12 | level-12-network-partition | Split Cluster | Two node groups can't talk — NetworkPolicy too broad |
| 13 | level-13-rbac-lockout | Locked Out | Service account rotation gone wrong — app can't reach API |
| 14 | level-14-quota-storm | Quota Flood | CI/CD pipeline created hundreds of pods — quota exhausted |
| 15 | level-15-zombie-process | Zombie Pod | Pod reports Running but process is zombie — container runtime issue |
| 16 | level-16-multi-region-sync | Region Lag | Multi-cluster sync broken — active/passive failover stuck |
| 17 | level-17-full-incident | P0 Incident | 5 simultaneous failures across storage, network, RBAC, quota, DNS |
| 18 | level-18-grand-master | Grand Master | All 12 modules contribute one failure — the ultimate 12-issue incident |

---

## XP Plan (updated totals)

| Module | Levels | XP/level avg | Module Total |
|-------|--------|-------------|-------------|
| 1 - Foundations | 20 | 140 | 2,800 |
| 2 - Workloads | 15 | 175 | 2,625 |
| 3 - Networking | 15 | 200 | 3,000 |
| 4 - Storage | 15 | 200 | 3,000 |
| 5 - Security | 15 | 250 | 3,750 |
| 6 - Observability | 15 | 250 | 3,750 |
| 7 - GitOps | 15 | 300 | 4,500 |
| 8 - CI/CD | 18 | 275 | 4,950 |
| 9 - Scheduling | 18 | 300 | 5,400 |
| 10 - Operators | 18 | 325 | 5,850 |
| 11 - Performance | 18 | 350 | 6,300 |
| 12 - War Games | 18 | 400 | 7,200 |
| **Total** | **200** | | **~53,125** |

---

## Implementation Order
Tackle one phase per session. Each phase = one `create_levels_phaseN.py` script that writes all the level directories, then delete the script.
