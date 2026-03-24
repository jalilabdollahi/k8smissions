#!/usr/bin/env python3
"""Learning-focused common mistakes docs for K8sMissions levels."""

from __future__ import annotations

import re
import textwrap


def _level_number(dir_name: str) -> str:
    match = re.match(r"level-(\d+)-", dir_name)
    return match.group(1) if match else "?"


def _level_text(level: dict) -> str:
    concepts = " ".join(level.get("concepts", []))
    return " ".join(
        [
            level.get("module", ""),
            level.get("dir_name", ""),
            level.get("name", ""),
            level.get("description", ""),
            level.get("fix", ""),
            level.get("validate", ""),
            concepts,
        ]
    ).lower()


def _category(level: dict) -> str:
    text = _level_text(level)
    module = level.get("module", "")

    module_defaults = {
        "module-2-workloads": "workload-controllers",
        "module-3-networking": "service-networking",
        "module-4-storage": "storage-state",
        "module-5-security": "security-access",
        "module-6-observability": "observability-debugging",
        "module-7-gitops": "gitops-delivery",
    }
    if module in module_defaults:
        return module_defaults[module]

    rules = [
        (
            "service-networking",
            [
                "service",
                "endpoints",
                "endpoint",
                "dns",
                "ingress",
                "networkpolicy",
                "nodeport",
                "loadbalancer",
                "headless",
                "session affinity",
                "cross-namespace",
                "cross namespace",
            ],
        ),
        (
            "scheduling-capacity",
            [
                "pending",
                "node-selector",
                "node selector",
                "node affinity",
                "taints",
                "tolerations",
                "scheduling",
                "autoscaler",
                "capacity",
                "allocatable",
                "priority",
                "greedy",
            ],
        ),
        (
            "workload-controllers",
            [
                "deployment",
                "replicaset",
                "statefulset",
                "rollingupdate",
                "rolling update",
                "rollout",
                "canary",
                "blue-green",
                "blue green",
                "hpa",
                "poddisruptionbudget",
                "pdb",
                "graceful shutdown",
            ],
        ),
        (
            "container-failures",
            [
                "crashloop",
                "imagepull",
                "oom",
                "exit code",
                "env",
                "configmap",
                "secret",
                "multi-container",
                "multi container",
                "initcontainer",
                "initcontainers",
                "init container",
                "log debugging",
            ],
        ),
    ]

    for category, keywords in rules:
        if any(keyword in text for keyword in keywords):
            return category
    return "container-failures"


def _focus(level: dict, category: str) -> str:
    text = _level_text(level)

    if category == "gitops-delivery":
        focus_map = [
            ("ArgoCD sync status and namespace prerequisites", ["argocd"]),
            ("Helm values and release history", ["helm"]),
            ("Kustomize overlays and patch targeting", ["kustomize", "overlay"]),
            ("environment promotion and config drift", ["multi-env", "environment", "promotion", "production"]),
            ("GitOps source of truth and reconciliation", ["gitops", "externalsecret", "external secrets", "runbook"]),
        ]
    elif category == "observability-debugging":
        focus_map = [
            ("probe behavior and timing", ["livenessprobe", "readinessprobe", "startupprobe", "probe", "liveness", "readiness"]),
            ("events, logs, and metrics correlation", ["metrics", "events", "logs", "debug", "timeline"]),
            ("restart reasons and container state history", ["restart", "oom", "exit code"]),
            ("node pressure and eviction signals", ["node pressure", "memorypressure", "diskpressure", "pidpressure"]),
        ]
    elif category == "security-access":
        focus_map = [
            ("RBAC scope and bindings", ["rbac", "rolebinding", "clusterrole", "serviceaccount", "least privilege", "forbidden"]),
            ("pod security settings", ["securitycontext", "runasnonroot", "pod security", "restricted", "capabilities"]),
            ("quota and namespace limits", ["resourcequota", "limitrange", "quota"]),
            ("scheduling and disruption safety controls", ["priorityclass", "poddisruptionbudget", "taints", "affinity"]),
        ]
    elif category == "storage-state":
        focus_map = [
            ("PVC/PV binding", ["pvc", "pv"]),
            ("volume mount path and file projection", ["mount", "configmap key", "projection"]),
            ("storage class selection", ["storageclass"]),
            ("persistent vs ephemeral storage", ["emptydir", "reclaim"]),
            ("filesystem ownership and volume permissions", ["fsgroup", "permissions"]),
        ]
    elif category == "service-networking":
        focus_map = [
            ("Ingress path and backend mapping", ["ingress"]),
            ("headless Service DNS", ["headless"]),
            ("NodePort reachability", ["nodeport"]),
            ("LoadBalancer behavior in local clusters", ["loadbalancer"]),
            ("NetworkPolicy allow rules", ["networkpolicy"]),
            ("session affinity behavior", ["session affinity"]),
            ("cross-namespace service discovery", ["cross-namespace", "cross namespace", "fqdn"]),
            ("Service selectors and endpoints", ["selector", "endpoints", "endpoint", "service"]),
        ]
    elif category == "workload-controllers":
        focus_map = [
            ("HPA signals and scaling boundaries", ["hpa", "autoscaler blind"]),
            ("rollout and controller state", ["deployment", "rollout", "replicaset"]),
            ("StatefulSet identity and stable storage", ["statefulset", "headless service", "volumeclaimtemplates"]),
            ("probe behavior and timing", ["liveness", "readiness", "startup", "probe"]),
            ("traffic shifting and safe rollout strategy", ["canary", "blue-green", "blue green", "maxsurge", "maxunavailable"]),
            ("disruption budgets and maintenance windows", ["poddisruptionbudget", "pdb", "eviction"]),
        ]
    elif category == "scheduling-capacity":
        focus_map = [
            ("node scheduling constraints", ["node-selector", "node selector", "node affinity", "taint", "toleration"]),
            ("requests, capacity, and scheduler fit", ["pending", "capacity", "allocatable", "requests", "greedy"]),
            ("cluster autoscaling prerequisites", ["autoscaler"]),
        ]
    else:
        focus_map = [
            ("image pull and registry resolution", ["imagepull", "image pull", "registry", "tag"]),
            ("container startup and runtime behavior", ["crashloop", "args", "command", "init", "sidecar"]),
            ("configuration injection through env or mounted data", ["env", "configmap", "secret"]),
            ("memory limits and OOM behavior", ["oom", "memory"]),
            ("log-driven application debugging", ["logs", "log debugging", "silent failure"]),
        ]

    for label, keywords in focus_map:
        if any(keyword in text for keyword in keywords):
            return label
    return "the real source of the failure"


def _category_commands(category: str) -> str:
    commands = {
        "container-failures": "\n".join(
            [
                "kubectl get pods -n k8smissions",
                "kubectl describe pod <pod> -n k8smissions",
                "kubectl logs <pod> -n k8smissions --previous",
            ]
        ),
        "workload-controllers": "\n".join(
            [
                "kubectl get deploy,statefulset,rs -n k8smissions",
                "kubectl rollout status deployment/<name> -n k8smissions",
                "kubectl describe deployment <name> -n k8smissions",
            ]
        ),
        "service-networking": "\n".join(
            [
                "kubectl get svc,endpoints,endpointslices -n k8smissions",
                "kubectl describe service <name> -n k8smissions",
                "kubectl get pods -n k8smissions --show-labels",
            ]
        ),
        "storage-state": "\n".join(
            [
                "kubectl get pv,pvc,storageclass -n k8smissions",
                "kubectl describe pvc <name> -n k8smissions",
                "kubectl describe pod <pod> -n k8smissions",
            ]
        ),
        "security-access": "\n".join(
            [
                "kubectl auth can-i <verb> <resource> -n k8smissions --as=system:serviceaccount:k8smissions:<sa>",
                "kubectl describe role,rolebinding,serviceaccount -n k8smissions",
                "kubectl describe pod <pod> -n k8smissions",
            ]
        ),
        "observability-debugging": "\n".join(
            [
                "kubectl get events -n k8smissions --sort-by=.lastTimestamp",
                "kubectl top pods -n k8smissions",
                "kubectl logs <pod> -n k8smissions --previous",
            ]
        ),
        "gitops-delivery": "\n".join(
            [
                "helm status <release> -n k8smissions || true",
                "argocd app get <app> || true",
                "kubectl get all -n k8smissions",
            ]
        ),
        "scheduling-capacity": "\n".join(
            [
                "kubectl describe pod <pod> -n k8smissions",
                "kubectl get nodes --show-labels",
                "kubectl describe node <node>",
            ]
        ),
    }
    return commands[category]


def _category_checklist(category: str, level: dict) -> list[str]:
    validate = level.get("validate", "Confirm the healthy state with the validator.")
    checks = {
        "container-failures": [
            "The pod is no longer restarting and stays healthy long enough to observe.",
            "You can explain whether the failure came from image pull, process exit, config, or memory pressure.",
            validate,
        ],
        "workload-controllers": [
            "The controller reports the desired number of ready replicas.",
            "You verified rollout status instead of trusting a single pod snapshot.",
            validate,
        ],
        "service-networking": [
            "The Service or Ingress now points to Ready backends.",
            "You verified selectors, ports, paths, or DNS names end-to-end.",
            validate,
        ],
        "storage-state": [
            "The claim or mount now matches the expected storage behavior.",
            "You verified access mode, mount path, or permissions at the place the app actually uses.",
            validate,
        ],
        "security-access": [
            "The workload has only the permission level it actually needs.",
            "You verified whether the denial came from RBAC, admission, or runtime user settings.",
            validate,
        ],
        "observability-debugging": [
            "You used more than one signal: events, logs, metrics, or probe state.",
            "You can explain why the chosen signal was the fastest one for this failure.",
            validate,
        ],
        "gitops-delivery": [
            "The declared source of truth and the live cluster match again.",
            "You checked the controller status instead of only the workload pods.",
            validate,
        ],
        "scheduling-capacity": [
            "The pod can now land on a node that satisfies its constraints.",
            "You verified labels, taints, requests, or capacity instead of guessing.",
            validate,
        ],
    }
    return checks[category]


def _mistakes_for(category: str, level: dict) -> list[dict[str, str]]:
    name = level.get("name", level.get("dir_name", "This level"))
    focus = _focus(level, category)
    fix = level.get("fix", "Apply the smallest change that restores the healthy state.")
    validate = level.get("validate", "Run the validator after the fix.")

    base = {
        "container-failures": [
            {
                "title": "Treating the status as the root cause",
                "what": f"Players see a failing pod in {name} and immediately edit random fields without first checking why the container stopped.",
                "why": "Statuses like CrashLoopBackOff, ImagePullBackOff, and OOMKilled are symptoms. The real answer is usually in events, exit reasons, or the last container logs.",
                "correct": f"Start from {focus}: inspect the pod, read the events, and only then change the manifest field that actually caused the failure.",
                "learning": "Kubernetes tells you what happened before you touch the YAML. Read the signal first, patch second.",
            },
            {
                "title": "Fixing the pod but not the source field",
                "what": "Players patch a live pod, restart it, or try a temporary shell workaround.",
                "why": "If the real issue is in command/args, image, env, config, or memory settings, a manual pod tweak disappears as soon as the controller recreates it.",
                "correct": f"Apply the fix at the owning manifest level so the pod comes back healthy for the right reason. Objective reminder: {fix}",
                "learning": "Always fix the declarative source of truth, not the current container instance.",
            },
            {
                "title": "Ignoring restart history and last termination state",
                "what": "Players look only at the current container state and miss what happened one restart ago.",
                "why": "The current process may not have failed yet, but the previous one already explains the bug through exit code, reason, or previous logs.",
                "correct": "Check previous logs and the last terminated container state before deciding what to change.",
                "learning": "The last termination often contains the most useful evidence in startup failures.",
            },
            {
                "title": "Stopping after the pod starts once",
                "what": "Players see one brief Running state and assume the mission is solved.",
                "why": "Some failures return after another restart cycle, a readiness check, or a delayed memory spike.",
                "correct": f"Let the pod stay up long enough, re-check restart count, then validate. Final check: {validate}",
                "learning": "A stable workload is different from a momentarily lucky workload.",
            },
        ],
        "workload-controllers": [
            {
                "title": "Editing pods instead of the controller",
                "what": f"Players patch an individual pod in {name} because it is the easiest object to see.",
                "why": "Deployments, StatefulSets, Jobs, and HPAs recreate pods from their own templates. A pod-only fix is wiped out on the next reconciliation loop.",
                "correct": "Find the owning controller and change the template or strategy there, then watch the rollout.",
                "learning": "Controllers own pods. Sustainable fixes live at the controller layer.",
            },
            {
                "title": "Skipping rollout history and status",
                "what": "Players apply a change and jump straight to validation.",
                "why": "A rollout can still be progressing, stuck, or paused even if a few pods look healthy for a moment.",
                "correct": "Use rollout status, describe the controller, and inspect related ReplicaSets before deciding the fix worked.",
                "learning": "Healthy pods are useful evidence, but controller status is the source of truth for workload health.",
            },
            {
                "title": "Confusing readiness, availability, and desired state",
                "what": "Players count pods manually and stop there.",
                "why": "A rollout can have the right replica count while still serving zero traffic because probes, surge rules, or disruption budgets are blocking availability.",
                "correct": f"Verify the workload from the controller perspective and the traffic perspective. In this level the focus is {focus}.",
                "learning": "Replica count alone does not prove safe delivery.",
            },
            {
                "title": "Making a traffic change without a rollback plan",
                "what": "Players switch selectors, versions, or rollout strategy in one jump and hope it holds.",
                "why": "Blue-green, canary, and rollout strategy changes are safe only when you know how to undo them quickly.",
                "correct": f"Use the smallest reversible change, verify behavior, then continue. Success target: {validate}",
                "learning": "Good rollout work is as much about controlled rollback as forward progress.",
            },
        ],
        "service-networking": [
            {
                "title": "Checking pods but not the traffic path",
                "what": f"Players see Running pods in {name} and assume networking must be fine.",
                "why": "Traffic can still fail because selectors, endpoints, ports, DNS, Ingress rules, or policies are wrong even when the pod itself is healthy.",
                "correct": f"Trace the request path end-to-end with the focus on {focus}. Confirm that each hop points to the next one correctly.",
                "learning": "Networking issues are usually path-mapping problems, not pod-liveness problems.",
            },
            {
                "title": "Mixing up names, ports, or paths",
                "what": "Players change several values at once without proving which mapping is broken.",
                "why": "A single mismatch in selector labels, `targetPort`, DNS name, namespace, or Ingress path can break everything while the rest of the YAML is correct.",
                "correct": "Compare the consumer and provider fields directly instead of guessing: label-to-selector, port-to-targetPort, path-to-backend, name-to-FQDN.",
                "learning": "Most service connectivity bugs are mismatches between two objects that both look valid in isolation.",
            },
            {
                "title": "Forgetting namespace and readiness boundaries",
                "what": "Players use short service names everywhere or test against pods that are not Ready yet.",
                "why": "Cross-namespace DNS needs the right name, and Services only route to Ready endpoints unless a feature explicitly changes that.",
                "correct": "Check namespace scope, ready endpoints, and policy rules before assuming a packet should be able to flow.",
                "learning": "Discovery and reachability are constrained by scope and readiness, not just object existence.",
            },
            {
                "title": "Validating from the wrong place",
                "what": "Players test the service from a context that bypasses the broken hop.",
                "why": "Curling the pod IP, port-forwarding, or using localhost can hide the exact layer that is still misconfigured.",
                "correct": f"Validate through the same path the workload is supposed to use. End goal: {validate}",
                "learning": "Your test path should match the production path you are trying to repair.",
            },
        ],
        "storage-state": [
            {
                "title": "Troubleshooting the app before the storage object",
                "what": f"Players look only at application logs in {name} and skip PV/PVC status, mount definitions, or storage class details.",
                "why": "If the claim never binds, mounts to the wrong path, or uses the wrong access mode, the app is only reporting the consequence.",
                "correct": f"Start from {focus}: inspect the claim, the backing volume or class, and how the pod mounts it.",
                "learning": "Storage bugs are usually contract mismatches between claim, volume, and mount point.",
            },
            {
                "title": "Confusing persistent and pod-local state",
                "what": "Players assume data behavior is identical across `emptyDir`, PVCs, and per-pod StatefulSet volumes.",
                "why": "Different volume types have different lifecycles, sharing semantics, and safety characteristics.",
                "correct": "Choose the storage primitive that matches the workload lifecycle instead of copying a manifest pattern from another use case.",
                "learning": "Persistence is a design choice in Kubernetes, not a default property of all volumes.",
            },
            {
                "title": "Ignoring access mode, key projection, or permissions",
                "what": "Players fix only the resource name and miss the field the container actually relies on.",
                "why": "The correct claim can still fail if it is mounted to the wrong path, exposed through the wrong key, or blocked by filesystem ownership.",
                "correct": "Check the exact path, key, access mode, and security context the app uses at runtime.",
                "learning": "Working storage requires both correct attachment and correct in-container visibility.",
            },
            {
                "title": "Treating data operations as harmless",
                "what": "Players delete or recreate storage objects quickly to 'start fresh'.",
                "why": "Reclaim policy and binding behavior decide whether data survives. A fast reset can create irreversible loss in real clusters.",
                "correct": f"Understand the storage lifecycle before deleting anything. Then validate the intended safe state: {validate}",
                "learning": "Storage fixes are part troubleshooting and part data protection discipline.",
            },
        ],
        "security-access": [
            {
                "title": "Using a privileged shortcut instead of the minimal fix",
                "what": f"Players solve {name} by granting broad permissions or relaxing security constraints too far.",
                "why": "That may make the workload pass, but it teaches the wrong habit and hides the real boundary that Kubernetes is enforcing.",
                "correct": "Grant only the permission, binding, or security setting the workload actually needs, and no more.",
                "learning": "A correct security fix is precise. Over-permission is not a win.",
            },
            {
                "title": "Confusing scope: pod, namespace, or cluster",
                "what": "Players create the right-looking object in the wrong scope or bind the wrong subject.",
                "why": "RBAC and admission controls are highly scope-sensitive. A Role is not a ClusterRole, and a ServiceAccount in one namespace is a different identity from the same name elsewhere.",
                "correct": f"Verify subject, verb, resource, and scope explicitly. In this level the main focus is {focus}.",
                "learning": "Security failures are often scope mistakes, not syntax mistakes.",
            },
            {
                "title": "Ignoring how the denial is enforced",
                "what": "Players treat all 'forbidden' behavior as the same kind of problem.",
                "why": "Some denials come from RBAC, some from Pod Security Admission, and some from runtime UID, capability, or filesystem settings.",
                "correct": "Read the event or error message closely so you fix the right enforcement layer.",
                "learning": "You fix RBAC, admission, and runtime hardening in different places.",
            },
            {
                "title": "Not proving the exact permission or policy change",
                "what": "Players apply a change and stop when the workload starts once.",
                "why": "Without an explicit check, you may not know whether you fixed the intended rule or just changed something broad enough to hide it.",
                "correct": f"Use targeted verification such as `kubectl auth can-i` or admission events, then confirm the workload target: {validate}",
                "learning": "Security changes should be testable and explainable, not just 'it works now'.",
            },
        ],
        "observability-debugging": [
            {
                "title": "Relying on one signal only",
                "what": f"Players use just one command in {name}, such as logs or `kubectl top`, and stop there.",
                "why": "Observability works best when you correlate signals. Events tell you what Kubernetes decided, metrics show pressure, and logs show app behavior.",
                "correct": "Combine at least two signals before concluding the root cause.",
                "learning": "The fastest diagnosis usually comes from signal correlation, not a single favorite command.",
            },
            {
                "title": "Reading the wrong time window",
                "what": "Players inspect current state only and miss what happened seconds earlier.",
                "why": "Restarts, probe failures, and eviction events are easy to miss if you do not look at previous logs or sorted event history.",
                "correct": f"Build a timeline for {focus} using events, previous logs, and current status together.",
                "learning": "Incidents are stories over time. A static snapshot is rarely enough.",
            },
            {
                "title": "Debugging the symptom at the wrong layer",
                "what": "Players jump into a shell before deciding whether the problem is application, probe, node pressure, or missing metrics infrastructure.",
                "why": "That creates noise and wastes time when the cluster already exposes the answer through events, conditions, or controller state.",
                "correct": "Start with the cheapest cluster-level evidence, then drill into the container only if the evidence tells you to.",
                "learning": "Good debugging narrows the layer first, then the exact bug.",
            },
            {
                "title": "Fixing the symptom without updating the mental model",
                "what": "Players patch the manifest until validation passes but cannot explain why the signal changed.",
                "why": "That makes the next incident feel new even when it is the same class of failure.",
                "correct": f"After the fix, explain what the signal should look like in a healthy cluster. Success target: {validate}",
                "learning": "Observability is valuable when you can predict healthy vs unhealthy telemetry afterward.",
            },
        ],
        "gitops-delivery": [
            {
                "title": "Patching the live cluster instead of the source of truth",
                "what": f"Players use `kubectl edit` to hot-fix {name} and move on.",
                "why": "GitOps and release tools will overwrite that drift on the next sync, reconcile, or Helm upgrade.",
                "correct": f"Make the change in the declarative source that owns the resource. In this level the key focus is {focus}.",
                "learning": "In GitOps, the winning fix is the one that survives reconciliation.",
            },
            {
                "title": "Looking at pods but not the delivery controller",
                "what": "Players check workload pods without checking Helm history, ArgoCD sync status, or Kustomize overlay intent.",
                "why": "Delivery failures are often explained by the release layer before the pod layer.",
                "correct": "Inspect the release or sync controller first, then confirm what it rendered into the cluster.",
                "learning": "The deployment tool is part of the system you are debugging.",
            },
            {
                "title": "Forgetting dependencies around the application",
                "what": "Players fix the app manifest but miss prerequisites like namespaces, secrets, hooks, or supporting resources.",
                "why": "A perfectly valid app spec can still remain OutOfSync, unhealthy, or blocked if the surrounding dependency chain is incomplete.",
                "correct": "Check the environment contract around the app before assuming the chart or manifest is the only issue.",
                "learning": "Production delivery includes prerequisites, not just the main workload YAML.",
            },
            {
                "title": "No verification path back to stable state",
                "what": "Players apply multiple delivery changes at once and have no idea which one fixed it.",
                "why": "That makes rollback harder and weakens the lesson from the incident.",
                "correct": f"Use revision history, sync status, or a single reversible change, then validate. End goal: {validate}",
                "learning": "Controlled delivery work is incremental, observable, and reversible.",
            },
        ],
        "scheduling-capacity": [
            {
                "title": "Guessing instead of reading Pending events",
                "what": f"Players see an unscheduled pod in {name} and immediately start changing manifests.",
                "why": "The scheduler usually tells you exactly what constraint failed: labels, taints, insufficient CPU/memory, affinity, or policy.",
                "correct": "Describe the pod first and let the scheduler message narrow the fix.",
                "learning": "Pending is an explanation-rich state. Read it before guessing.",
            },
            {
                "title": "Treating constraints like preferences",
                "what": "Players assume node selectors, required affinity, taints, or hard resource requests are flexible hints.",
                "why": "Required scheduling constraints are binary. A single mismatch prevents placement completely.",
                "correct": f"Compare the pod requirements directly against cluster reality with a focus on {focus}.",
                "learning": "Scheduling is constraint matching, not best-effort magic.",
            },
            {
                "title": "Confusing requests, limits, and actual usage",
                "what": "Players check current node usage but ignore what the scheduler reserves for the pod.",
                "why": "Scheduling decisions are based on requests and allocatable capacity, not on what a workload happens to use right now.",
                "correct": "Verify requests, allocatable capacity, and taints/labels together before changing anything.",
                "learning": "Placement depends on reserved capacity and policy, not just live metrics.",
            },
            {
                "title": "Stopping before the pod is truly placeable",
                "what": "Players update one constraint and assume the scheduling problem is gone.",
                "why": "There can be a second blocker behind the first one, especially in capacity or multi-constraint scenarios.",
                "correct": f"Re-describe the pod after every change and keep going until the scheduler has no remaining objections. Final target: {validate}",
                "learning": "Scheduling fixes are complete only when every constraint chain is satisfied.",
            },
        ],
    }
    return base[category]


def render_common_mistakes(level: dict) -> str:
    category = _category(level)
    level_num = _level_number(level.get("dir_name", ""))
    title = level.get("name", level.get("dir_name", "Level"))
    commands = _category_commands(category)
    mistakes = _mistakes_for(category, level)
    checklist = _category_checklist(category, level)

    sections = []
    for index, mistake in enumerate(mistakes, start=1):
        sections.append(
            textwrap.dedent(
                f"""\
                ## ❌ Mistake #{index}: {mistake["title"]}

                **What players try:**
                {mistake["what"]}

                **Why it fails:**
                {mistake["why"]}

                **Correct approach:**
                {mistake["correct"]}

                **Key learning:**
                {mistake["learning"]}
                """
            ).strip()
        )

    checklist_md = "\n".join(f"- {item}" for item in checklist)

    return (
        f"# Common Mistakes - Level {level_num}: {title}\n\n"
        "## Fastest First Checks\n"
        "```bash\n"
        f"{commands}\n"
        "```\n\n"
        f"{chr(10).join(sections)}\n\n"
        "## What To Prove Before You Move On\n"
        f"{checklist_md}\n"
    )
