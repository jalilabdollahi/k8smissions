#!/usr/bin/env python3
"""Generate all K8sMissions level directories from the module descriptions."""

from __future__ import annotations

import json
import re
import shutil
import textwrap
from pathlib import Path

from common_mistakes_templates import render_common_mistakes

ROOT = Path(__file__).resolve().parents[1]
MODULES_DIR = ROOT / "modules"
NS = "k8smissions"
TEXT_SUFFIXES = {".yaml", ".yml", ".md", ".txt", ".sh"}



def clean_module_directories() -> None:
    for module_dir in MODULES_DIR.iterdir():
        if not module_dir.is_dir():
            continue
        for path in module_dir.iterdir():
            if path.is_dir():
                shutil.rmtree(path)


def normalize_text(text: str) -> str:
    return text


def parse_module_description(path: Path) -> list[dict]:
    levels: list[dict] = []
    current: dict | None = None
    current_key: str | None = None
    key_map = {
        "Name": "name",
        "Difficulty": "difficulty",
        "XP": "xp",
        "Time est.": "expected_time",
        "Description": "description",
        "Broken state": "broken_state",
        "Fix": "fix",
        "Validate": "validate",
        "Concepts": "concepts",
        "Hint 1": "hint_1",
        "Hint 2": "hint_2",
        "Hint 3": "hint_3",
        "Debrief": "debrief",
        "Folder": "folder",
    }
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        level_match = re.match(r"LEVEL\s+(\d+)\s+[—-]\s+([a-z0-9-]+)(?:\s+\((level-[^)]+)\))?", line.strip())
        if level_match:
            if current:
                levels.append(finalize_level(current, path.parent.name))
            current = {
                "number": int(level_match.group(1)),
                "slug": level_match.group(2),
                "folder": level_match.group(3) or "",
            }
            current_key = None
            continue

        if current is None:
            continue

        field_match = re.match(r"\s{2,}([A-Za-z0-9 .-]+?)\s*:\s*(.*)$", line)
        if field_match and field_match.group(1) in key_map:
            current_key = key_map[field_match.group(1)]
            current[current_key] = field_match.group(2).strip()
            continue

        if current_key and line.startswith(" " * 16):
            current[current_key] = f"{current.get(current_key, '')} {line.strip()}".strip()
        elif current_key and line.startswith(" " * 2) and ":" not in line and line.strip():
            current[current_key] = f"{current.get(current_key, '')} {line.strip()}".strip()
        else:
            current_key = None

    if current:
        levels.append(finalize_level(current, path.parent.name))
    return levels


def finalize_level(level: dict, module_name: str) -> dict:
    folder = level.get("folder") or f"level-{level['number']}-{level['slug']}"
    level["module"] = module_name
    level["dir_name"] = folder.rstrip("/").split("/")[-1]
    level["xp"] = int(level.get("xp") or 0)
    for key, value in list(level.items()):
        if isinstance(value, str):
            cleaned = value.strip()
            if len(cleaned) >= 2 and cleaned[0] == cleaned[-1] and cleaned[0] in {'"', "'"}:
                cleaned = cleaned[1:-1]
            level[key] = cleaned
    level["concepts"] = [part.strip() for part in re.split(r",\s*", level.get("concepts", "")) if part.strip()]
    level.setdefault("name", level["slug"].replace("-", " ").title())
    level.setdefault("difficulty", "intermediate")
    level.setdefault("description", "Investigate the broken Kubernetes resource and restore the expected state.")
    level.setdefault("fix", "Apply the corrected manifest or patch so the workload matches the expected healthy state.")
    level.setdefault("expected_time", "10m")
    level.setdefault("broken_state", level.get("description", "Inspect the broken resource state."))
    level.setdefault("validate", "Use the validator to confirm the repaired state.")
    level.setdefault("debrief", f"Review how the fix changed the cluster behavior for {level.get('name', level['slug'])}.")
    level.setdefault("hint_1", f"Start with: {level['broken_state']}")
    level.setdefault("hint_2", f"Goal state: {level.get('fix', level['validate'])}")
    level.setdefault("hint_3", f"Validation target: {level['validate']}")
    return level


def mission_doc(level: dict) -> str:
    mission = {
        "name": level["name"],
        "description": level["description"],
        "objective": level["fix"],
        "xp": int(level["xp"]),
        "difficulty": level["difficulty"],
        "expected_time": level["expected_time"],
        "concepts": level["concepts"],
        "module": level["module"],
        "level": level["dir_name"],
    }
    return json.dumps(mission, indent=2, ensure_ascii=False)


def debrief_doc(level: dict) -> str:
    concepts = ", ".join(level["concepts"])
    return textwrap.dedent(
        f"""\
        # {level["name"]}

        ## Situation
        {level["description"]}

        ## Successful Fix
        {level["fix"]}

        ## What To Validate
        {level["validate"]}

        ## Why It Matters
        {level["debrief"]}

        ## Concepts
        {concepts}
        """
    )


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + "\n", encoding="utf-8")


def write_shell(path: Path, content: str) -> None:
    write_text(path, textwrap.dedent(content))
    path.chmod(0o755)


def dump_resources(resources: list[dict]) -> str:
    return "\n---\n".join(json.dumps(resource, indent=2, ensure_ascii=False) for resource in resources)


def pod(name: str, image: str, *, command=None, args=None, env=None, resources=None, labels=None, node_selector=None, volumes=None, volume_mounts=None, init_containers=None, extra_containers=None, service_account=None) -> dict:
    spec = {
        "containers": [
            {
                "name": name,
                "image": image,
            }
        ]
    }
    container = spec["containers"][0]
    if command is not None:
        container["command"] = command
    if args is not None:
        container["args"] = args
    if env is not None:
        container["env"] = env
    if resources is not None:
        container["resources"] = resources
    if volume_mounts is not None:
        container["volumeMounts"] = volume_mounts
    if volumes is not None:
        spec["volumes"] = volumes
    if node_selector is not None:
        spec["nodeSelector"] = node_selector
    if init_containers is not None:
        spec["initContainers"] = init_containers
    if extra_containers is not None:
        spec["containers"].extend(extra_containers)
    if service_account is not None:
        spec["serviceAccountName"] = service_account
    return {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {"name": name, "namespace": NS, "labels": labels or {"app": name}},
        "spec": spec,
    }


def deployment(name: str, image: str, *, replicas=1, labels=None, pod_labels=None, command=None, args=None, env=None, resources=None, ports=None, strategy=None, readiness=None, liveness=None, startup=None, lifecycle=None, termination_grace_period=None, service_account=None) -> dict:
    tpl_labels = pod_labels or labels or {"app": name}
    container = {
        "name": name,
        "image": image,
    }
    if command is not None:
        container["command"] = command
    if args is not None:
        container["args"] = args
    if env is not None:
        container["env"] = env
    if resources is not None:
        container["resources"] = resources
    if ports is not None:
        container["ports"] = ports
    if readiness is not None:
        container["readinessProbe"] = readiness
    if liveness is not None:
        container["livenessProbe"] = liveness
    if startup is not None:
        container["startupProbe"] = startup
    if lifecycle is not None:
        container["lifecycle"] = lifecycle
    pod_spec = {"containers": [container]}
    if service_account is not None:
        pod_spec["serviceAccountName"] = service_account
    if termination_grace_period is not None:
        pod_spec["terminationGracePeriodSeconds"] = termination_grace_period
    return {
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {"name": name, "namespace": NS, "labels": labels or {"app": name}},
        "spec": {
            "replicas": replicas,
            "selector": {"matchLabels": tpl_labels},
            "template": {
                "metadata": {"labels": tpl_labels},
                "spec": pod_spec,
            },
            **({"strategy": strategy} if strategy else {}),
        },
    }


def service(name: str, selector: dict, *, port: int, target_port: int, service_type: str = "ClusterIP") -> dict:
    return {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {"name": name, "namespace": NS},
        "spec": {
            "type": service_type,
            "selector": selector,
            "ports": [{"port": port, "targetPort": target_port}],
        },
    }


def configmap(name: str, data: dict) -> dict:
    return {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": name, "namespace": NS},
        "data": data,
    }


def secret(name: str, data: dict) -> dict:
    return {
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {"name": name, "namespace": NS},
        "type": "Opaque",
        "stringData": data,
    }


def namespace(name: str) -> dict:
    return {"apiVersion": "v1", "kind": "Namespace", "metadata": {"name": name}}


def generic_validate(script_body: str) -> str:
    return textwrap.dedent(
        f"""\
        #!/bin/bash
        set -euo pipefail
        NS="{NS}"

        {script_body.strip()}
        """
    )


def spec_check_deployment(name: str, jsonpath: str, expected: str, success: str, failure: str) -> str:
    return generic_validate(
        f"""
        VALUE=$(kubectl get deployment {name} -n "$NS" -o jsonpath='{jsonpath}' 2>/dev/null || true)
        if [ "$VALUE" = "{expected}" ]; then
          echo "✅ PASS: {success}"
          exit 0
        fi
        echo "❌ FAIL: {failure}. Current value: '$VALUE'"
        exit 1
        """
    )


def running_pod_validate(name: str, success: str, failure: str) -> str:
    return generic_validate(
        f"""
        STATUS=$(kubectl get pod {name} -n "$NS" -o jsonpath='{{.status.phase}}' 2>/dev/null || true)
        READY=$(kubectl get pod {name} -n "$NS" -o jsonpath='{{.status.containerStatuses[0].ready}}' 2>/dev/null || true)
        if [ "$STATUS" = "Running" ] && [ "$READY" = "true" ]; then
          echo "✅ PASS: {success}"
          exit 0
        fi
        echo "❌ FAIL: {failure}. Status='$STATUS' Ready='$READY'"
        exit 1
        """
    )


def write_level_docs(level: dict, target: Path) -> None:
    write_text(target / "mission.yaml", mission_doc(level))
    write_text(target / "hint-1.txt", level["hint_1"])
    write_text(target / "hint-2.txt", level["hint_2"])
    write_text(target / "hint-3.txt", level["hint_3"])
    write_text(target / "debrief.md", debrief_doc(level))
    write_text(target / "common-mistakes.md", render_common_mistakes(level))


def build_level(target: Path, level: dict, payload: dict) -> None:
    write_level_docs(level, target)
    write_text(target / "broken.yaml", payload["broken"])
    write_text(target / "solution.yaml", payload["solution"])
    write_shell(target / "validate.sh", payload["validate"])
    for relative_path, content in payload.get("extras", {}).items():
        path = target / relative_path
        if relative_path.endswith(".sh"):
            write_shell(path, content)
        else:
            write_text(path, content)


def build_custom_level(level: dict) -> dict:
    slug = level["slug"]
    builders = {
        "crashloop": build_crashloop,
        "env-variables": build_env_variables,
        "configmap-basics": build_configmap_basics,
        "secrets-basics": build_secrets_basics,
        "oomkilled": build_oom_level,
        "node-selector": build_node_selector,
        "deployment-replicas": build_deployment_replicas,
        "hpa-scaling": build_hpa_scaling,
        "metrics-server-missing": build_metrics_server,
        "pod-events-analysis": build_events_imagepull,
        "resource-top": build_resource_top,
        "log-aggregation": build_log_aggregation,
        "liveness-vs-readiness": build_probe_swap,
        "container-restart-cause": build_restart_cause,
        "node-pressure": build_node_pressure,
        "probe-tuning": build_probe_tuning,
        "exec-debugging": build_exec_debugging,
        "cluster-events": build_cluster_events,
        "helm-broken-values": build_helm_values,
        "helm-rollback": build_helm_rollback,
        "kustomize-overlay": build_kustomize_overlay,
        "argocd-sync": build_argocd_sync,
        "multi-env-config": build_multi_env_config,
        "graceful-shutdown": build_graceful_shutdown,
        "external-secrets": build_external_secrets,
        "cluster-autoscaler": build_cluster_autoscaler,
        "production-runbook": build_production_runbook,
        "grand-finale": build_grand_finale,
    }
    if slug not in builders:
        raise KeyError(f"No builder implemented for {level['module']}/{level['dir_name']}")
    return builders[slug](level)


def build_crashloop(level: dict) -> dict:
    broken = dump_resources([pod("crashloop-pod", "busybox:1.36", args=["/scripts/start.sh"])])
    solution = dump_resources([pod("crashloop-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"])])
    validate = generic_validate(
        """
        STATUS=$(kubectl get pod crashloop-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
        RESTARTS=$(kubectl get pod crashloop-pod -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || true)
        if [ "$STATUS" = "Running" ] && [ "$RESTARTS" = "0" ]; then
          echo "✅ PASS: Pod is stable and no longer restarting"
          exit 0
        fi
        echo "❌ FAIL: Pod status='$STATUS' restarts='$RESTARTS'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_env_variables(level: dict) -> dict:
    broken = dump_resources([
        pod(
            "env-pod",
            "busybox:1.36",
            command=["/bin/sh", "-c", 'if [ -z "$DATABASE_URL" ]; then echo "DATABASE_URL not set, exiting"; exit 1; fi; sleep 3600'],
        )
    ])
    solution = dump_resources([
        pod(
            "env-pod",
            "busybox:1.36",
            command=["/bin/sh", "-c", 'if [ -z "$DATABASE_URL" ]; then echo "DATABASE_URL not set, exiting"; exit 1; fi; sleep 3600'],
            env=[{"name": "DATABASE_URL", "value": "postgres://localhost/app"}],
        )
    ])
    return {
        "broken": broken,
        "solution": solution,
        "validate": running_pod_validate("env-pod", "Pod is running with DATABASE_URL set", "Pod is still crashing"),
    }


def build_configmap_basics(level: dict) -> dict:
    volumes = [{"name": "config", "configMap": {"name": "app-config"}}]
    mounts = [{"name": "config", "mountPath": "/etc/app"}]
    broken = dump_resources([
        pod("configmap-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"], volumes=volumes, volume_mounts=mounts)
    ])
    solution = dump_resources([
        configmap("app-config", {"APP_MODE": "production"}),
        pod("configmap-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"], volumes=volumes, volume_mounts=mounts),
    ])
    validate = generic_validate(
        """
        if ! kubectl get configmap app-config -n "$NS" >/dev/null 2>&1; then
          echo "❌ FAIL: ConfigMap app-config does not exist"
          exit 1
        fi
        STATUS=$(kubectl get pod configmap-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
        if [ "$STATUS" = "Running" ]; then
          echo "✅ PASS: ConfigMap exists and pod is running"
          exit 0
        fi
        echo "❌ FAIL: Pod status is '$STATUS'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_secrets_basics(level: dict) -> dict:
    broken = dump_resources([
        pod(
            "secret-pod",
            "busybox:1.36",
            command=["/bin/sh", "-c", 'if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then exit 1; fi; sleep 3600'],
            env=[
                {"name": "DB_USERNAME", "valueFrom": {"secretKeyRef": {"name": "db-credentials", "key": "username"}}},
                {"name": "DB_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "db-credentials", "key": "password"}}},
            ],
        )
    ])
    solution_resources = [
        secret("db-credentials", {"username": "appuser", "password": "mypassword"}),
        pod(
            "secret-pod",
            "busybox:1.36",
            command=["/bin/sh", "-c", 'if [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then exit 1; fi; sleep 3600'],
            env=[
                {"name": "DB_USERNAME", "valueFrom": {"secretKeyRef": {"name": "db-credentials", "key": "username"}}},
                {"name": "DB_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "db-credentials", "key": "password"}}},
            ],
        ),
    ]
    validate = generic_validate(
        """
        if ! kubectl get secret db-credentials -n "$NS" >/dev/null 2>&1; then
          echo "❌ FAIL: Secret db-credentials does not exist"
          exit 1
        fi
        STATUS=$(kubectl get pod secret-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
        if [ "$STATUS" = "Running" ]; then
          echo "✅ PASS: Secret exists and pod is running"
          exit 0
        fi
        echo "❌ FAIL: Pod status is '$STATUS'"
        exit 1
        """
    )
    return {"broken": broken, "solution": dump_resources(solution_resources), "validate": validate}


def build_oom_level(level: dict) -> dict:
    resources_low = {"limits": {"memory": "64Mi"}, "requests": {"memory": "32Mi"}}
    resources_ok = {"limits": {"memory": "256Mi"}, "requests": {"memory": "64Mi"}}
    command = ["python", "-c", "data=['x'*1024*1024 for _ in range(128)]; import time; time.sleep(3600)"]
    broken = dump_resources([pod("oom-pod", "python:3.11-alpine", command=command, resources=resources_low)])
    solution = dump_resources([pod("oom-pod", "python:3.11-alpine", command=command, resources=resources_ok)])
    validate = generic_validate(
        """
        LIMIT=$(kubectl get pod oom-pod -n "$NS" -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
        if [ "$LIMIT" = "256Mi" ]; then
          echo "✅ PASS: Memory limit increased to 256Mi"
          exit 0
        fi
        echo "❌ FAIL: Expected memory limit 256Mi, got '$LIMIT'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_node_selector(level: dict) -> dict:
    broken = dump_resources([pod("selector-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"], node_selector={"mission": "moon-base"})])
    solution = dump_resources([pod("selector-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"], node_selector={"kubernetes.io/os": "linux"})])
    validate = generic_validate(
        """
        STATUS=$(kubectl get pod selector-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
        if [ "$STATUS" = "Running" ]; then
          echo "✅ PASS: Pod scheduled successfully"
          exit 0
        fi
        echo "❌ FAIL: Pod status is '$STATUS'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_deployment_replicas(level: dict) -> dict:
    broken = dump_resources([deployment("ghost-deployment", "nginx:1.27.4", replicas=0, ports=[{"containerPort": 80}])])
    solution = dump_resources([deployment("ghost-deployment", "nginx:1.27.4", replicas=3, ports=[{"containerPort": 80}])])
    validate = generic_validate(
        """
        READY=$(kubectl get deployment ghost-deployment -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
        if [ "$READY" = "3" ]; then
          echo "✅ PASS: Deployment has 3 ready replicas"
          exit 0
        fi
        echo "❌ FAIL: Expected 3 ready replicas, got '$READY'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_metrics_server(level: dict) -> dict:
    broken = dump_resources([deployment("metrics-server", "nginx:1.27.4", replicas=0)])
    solution = dump_resources([deployment("metrics-server", "nginx:1.27.4", replicas=1)])
    validate = generic_validate(
        """
        REPLICAS=$(kubectl get deployment metrics-server -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
        if [ "$REPLICAS" = "1" ]; then
          echo "✅ PASS: metrics-server proxy deployment is ready"
          exit 0
        fi
        echo "❌ FAIL: metrics-server proxy is not ready"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_hpa_scaling(level: dict) -> dict:
    broken = dump_resources([
        deployment("web-backend", "nginx:1.27.4", replicas=1, resources={"requests": {"cpu": "200m"}, "limits": {"cpu": "500m"}}),
        {
            "apiVersion": "autoscaling/v2",
            "kind": "HorizontalPodAutoscaler",
            "metadata": {"name": "web-backend-hpa", "namespace": NS},
            "spec": {
                "scaleTargetRef": {"apiVersion": "apps/v1", "kind": "Deployment", "name": "web-backend"},
                "minReplicas": 1,
                "maxReplicas": 5,
                "metrics": [
                    {
                        "type": "Resource",
                        "resource": {"name": "cpu", "target": {"type": "Utilization", "averageUtilization": 50}},
                    }
                ],
            },
        },
        deployment("metrics-server", "nginx:1.27.4", replicas=0),
    ])
    solution = dump_resources([
        deployment("web-backend", "nginx:1.27.4", replicas=1, resources={"requests": {"cpu": "200m"}, "limits": {"cpu": "500m"}}),
        {
            "apiVersion": "autoscaling/v2",
            "kind": "HorizontalPodAutoscaler",
            "metadata": {"name": "web-backend-hpa", "namespace": NS},
            "spec": {
                "scaleTargetRef": {"apiVersion": "apps/v1", "kind": "Deployment", "name": "web-backend"},
                "minReplicas": 1,
                "maxReplicas": 5,
                "metrics": [
                    {
                        "type": "Resource",
                        "resource": {"name": "cpu", "target": {"type": "Utilization", "averageUtilization": 50}},
                    }
                ],
            },
        },
        deployment("metrics-server", "nginx:1.27.4", replicas=1),
    ])
    validate = generic_validate(
        """
        METRICS=$(kubectl get deployment metrics-server -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
        if [ "$METRICS" = "1" ]; then
          echo "✅ PASS: Metrics server proxy is running"
          exit 0
        fi
        echo "❌ FAIL: metrics-server proxy is not ready"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_events_imagepull(level: dict) -> dict:
    broken = dump_resources([pod("events-pod", "nginx:broken-tag")])
    solution = dump_resources([pod("events-pod", "nginx:1.27.4")])
    return {"broken": broken, "solution": solution, "validate": running_pod_validate("events-pod", "Pod is running", "Pod is not running")}


def build_resource_top(level: dict) -> dict:
    broken = dump_resources([
        deployment(
            "cpu-hog",
            "busybox:1.36",
            command=["/bin/sh", "-c", "while true; do :; done"],
            resources={"requests": {"cpu": "100m", "memory": "32Mi"}},
        )
    ])
    solution = dump_resources([
        deployment(
            "cpu-hog",
            "busybox:1.36",
            command=["/bin/sh", "-c", "while true; do :; done"],
            resources={"requests": {"cpu": "100m", "memory": "32Mi"}, "limits": {"cpu": "200m", "memory": "64Mi"}},
        )
    ])
    return {
        "broken": broken,
        "solution": solution,
        "validate": spec_check_deployment("cpu-hog", "{.spec.template.spec.containers[0].resources.limits.cpu}", "200m", "CPU limit set to 200m", "CPU limit has not been fixed"),
    }


def build_log_aggregation(level: dict) -> dict:
    broken = dump_resources([pod("logs-pod", "busybox:1.36", args=["/missing.sh"])])
    solution = dump_resources([pod("logs-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"])])
    return {"broken": broken, "solution": solution, "validate": running_pod_validate("logs-pod", "Pod is stable", "Pod still is not stable")}


def build_probe_swap(level: dict) -> dict:
    liveness_bad = {"httpGet": {"path": "/api/v1/ready", "port": 8080}, "initialDelaySeconds": 5, "periodSeconds": 5}
    liveness_good = {"httpGet": {"path": "/healthz", "port": 8080}, "initialDelaySeconds": 5, "periodSeconds": 5}
    readiness_good = {"httpGet": {"path": "/api/v1/ready", "port": 8080}, "initialDelaySeconds": 10, "periodSeconds": 5}
    broken = dump_resources([deployment("probe-app", "hashicorp/http-echo:1.0.0", args=["-text=ok", "-listen=:8080"], ports=[{"containerPort": 8080}], liveness=liveness_bad)])
    solution = dump_resources([deployment("probe-app", "hashicorp/http-echo:1.0.0", args=["-text=ok", "-listen=:8080"], ports=[{"containerPort": 8080}], liveness=liveness_good, readiness=readiness_good)])
    validate = generic_validate(
        """
        LIVENESS=$(kubectl get deployment probe-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null || true)
        READINESS=$(kubectl get deployment probe-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
        if [ "$LIVENESS" = "/healthz" ] && [ "$READINESS" = "/api/v1/ready" ]; then
          echo "✅ PASS: Probe roles are correct"
          exit 0
        fi
        echo "❌ FAIL: liveness='$LIVENESS' readiness='$READINESS'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_restart_cause(level: dict) -> dict:
    return build_oom_level(level)


def build_node_pressure(level: dict) -> dict:
    broken = dump_resources([
        deployment(
            "memory-hog",
            "busybox:1.36",
            replicas=4,
            command=["/bin/sh", "-c", "dd if=/dev/zero of=/dev/null bs=1M count=512 && sleep 3600"],
            resources={"requests": {"memory": "64Mi"}},
        )
    ])
    solution = dump_resources([
        deployment(
            "memory-hog",
            "busybox:1.36",
            replicas=1,
            command=["/bin/sh", "-c", "sleep 3600"],
            resources={"requests": {"memory": "64Mi"}, "limits": {"memory": "128Mi"}},
        )
    ])
    validate = generic_validate(
        """
        REPLICAS=$(kubectl get deployment memory-hog -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
        LIMIT=$(kubectl get deployment memory-hog -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
        if [ "$REPLICAS" = "1" ] && [ "$LIMIT" = "128Mi" ]; then
          echo "✅ PASS: Memory pressure proxy has been reduced"
          exit 0
        fi
        echo "❌ FAIL: replicas='$REPLICAS' limit='$LIMIT'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_probe_tuning(level: dict) -> dict:
    liveness_bad = {"httpGet": {"path": "/healthz", "port": 8080}, "initialDelaySeconds": 5, "periodSeconds": 5}
    startup_good = {"httpGet": {"path": "/healthz", "port": 8080}, "failureThreshold": 30, "periodSeconds": 5}
    broken = dump_resources([deployment("slow-app", "hashicorp/http-echo:1.0.0", args=["-text=ready", "-listen=:8080"], ports=[{"containerPort": 8080}], liveness=liveness_bad)])
    solution = dump_resources([deployment("slow-app", "hashicorp/http-echo:1.0.0", args=["-text=ready", "-listen=:8080"], ports=[{"containerPort": 8080}], liveness=liveness_bad, startup=startup_good)])
    validate = generic_validate(
        """
        STARTUP=$(kubectl get deployment slow-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].startupProbe.periodSeconds}' 2>/dev/null || true)
        if [ "$STARTUP" = "5" ]; then
          echo "✅ PASS: startupProbe configured"
          exit 0
        fi
        echo "❌ FAIL: startupProbe is missing"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_exec_debugging(level: dict) -> dict:
    cm_bad = configmap("app-config", {"config.json": '{"DB_HOST":"10.0.0.99","DB_PORT":5432}'})
    cm_good = configmap("app-config", {"config.json": '{"DB_HOST":"database.k8smissions.svc.cluster.local","DB_PORT":5432}'})
    volume = [{"name": "config", "configMap": {"name": "app-config"}}]
    mount = [{"name": "config", "mountPath": "/app"}]
    pod_manifest = pod("debug-pod", "busybox:1.36", command=["/bin/sh", "-c", "sleep 3600"], volumes=volume, volume_mounts=mount)
    broken = dump_resources([cm_bad, pod_manifest])
    solution = dump_resources([cm_good, pod_manifest])
    validate = generic_validate(
        """
        HOST=$(kubectl get configmap app-config -n "$NS" -o jsonpath='{.data.config\\.json}' 2>/dev/null | grep -o 'database.k8smissions.svc.cluster.local' || true)
        if [ -n "$HOST" ]; then
          echo "✅ PASS: ConfigMap points to the service DNS name"
          exit 0
        fi
        echo "❌ FAIL: ConfigMap still has the wrong DB host"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_cluster_events(level: dict) -> dict:
    broken = dump_resources([
        deployment(
            "incident-app",
            "busybox:1.36",
            command=["/bin/sh", "-c", "while true; do echo incident; sleep 5; done"],
            resources={"requests": {"memory": "32Mi"}, "limits": {"memory": "64Mi"}},
        )
    ])
    solution = dump_resources([
        deployment(
            "incident-app",
            "busybox:1.36",
            command=["/bin/sh", "-c", "while true; do echo incident; sleep 5; done"],
            resources={"requests": {"memory": "32Mi"}, "limits": {"memory": "256Mi"}},
        )
    ])
    extras = {
        "incident-log.txt": textwrap.dedent(
            """\
            12:00 pod/incident-app OOMKilled
            12:02 node/kind-worker MemoryPressure=True
            12:04 pod/incident-app restarted
            12:07 alerts firing: elevated restart rate
            """
        )
    }
    validate = generic_validate(
        """
        LIMIT=$(kubectl get deployment incident-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || true)
        if [ "$LIMIT" = "256Mi" ]; then
          echo "✅ PASS: Incident root cause has been mitigated"
          exit 0
        fi
        echo "❌ FAIL: Memory limit is still '$LIMIT'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate, "extras": extras}


def build_helm_values(level: dict) -> dict:
    broken = dump_resources([deployment("helm-app", "nginx:latest", ports=[{"containerPort": 80}])])
    solution = dump_resources([deployment("helm-app", "nginx:1.27.4", ports=[{"containerPort": 80}])])
    extras = {
        "chart/values.yaml": 'image:\n  repository: nginx\n  tag: ""\n',
        "chart/templates/deployment.yaml": "{{ .Values.image.repository }}:{{ .Values.image.tag | default \"latest\" }}\n",
    }
    validate = generic_validate(
        """
        IMAGE=$(kubectl get deployment helm-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
        if [ "$IMAGE" = "nginx:1.27.4" ]; then
          echo "✅ PASS: Helm proxy deployment is pinned to a version"
          exit 0
        fi
        echo "❌ FAIL: Deployment image is '$IMAGE'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate, "extras": extras}


def build_helm_rollback(level: dict) -> dict:
    setup = dump_resources([deployment("webapp", "nginx:1.27.4", ports=[{"containerPort": 80}])])
    broken = dump_resources([deployment("webapp", "nginx:broken-tag", ports=[{"containerPort": 80}])])
    solution = dump_resources([deployment("webapp", "nginx:1.27.4", ports=[{"containerPort": 80}])])
    extras = {"setup.yaml": setup}
    validate = generic_validate(
        """
        IMAGE=$(kubectl get deployment webapp -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
        if [ "$IMAGE" = "nginx:1.27.4" ]; then
          echo "✅ PASS: Deployment rolled back to the healthy image"
          exit 0
        fi
        echo "❌ FAIL: Deployment image is '$IMAGE'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate, "extras": extras}


def build_kustomize_overlay(level: dict) -> dict:
    broken = dump_resources([deployment("kustomize-app", "nginx:1.27.4", replicas=10)])
    solution = dump_resources([deployment("kustomize-app", "nginx:1.27.4", replicas=2)])
    extras = {
        "base/deployment.yaml": dump_resources([deployment("kustomize-app", "nginx:1.27.4", replicas=1)]),
        "overlays/staging/kustomization.yaml": textwrap.dedent(
            """\
            resources:
              - ../../base/deployment.yaml
            replicas:
              - name: kustomize-app
                count: 2
            """
        ),
        "overlays/production/kustomization.yaml": textwrap.dedent(
            """\
            resources:
              - ../../base/deployment.yaml
            replicas:
              - name: kustomize-app
                count: 10
            """
        ),
    }
    validate = generic_validate(
        """
        REPLICAS=$(kubectl get deployment kustomize-app -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
        if [ "$REPLICAS" = "2" ]; then
          echo "✅ PASS: Staging overlay proxy is applied"
          exit 0
        fi
        echo "❌ FAIL: Expected 2 replicas, got '$REPLICAS'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate, "extras": extras}


def build_argocd_sync(level: dict) -> dict:
    broken = dump_resources([configmap("argocd-application", {"status": "OutOfSync", "targetNamespace": "webapp-prod"})])
    solution = dump_resources([
        namespace("webapp-prod"),
        configmap("argocd-application", {"status": "Synced", "targetNamespace": "webapp-prod"}),
        {
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {"name": "webapp-app", "namespace": "webapp-prod"},
            "spec": {
                "replicas": 1,
                "selector": {"matchLabels": {"app": "webapp-app"}},
                "template": {
                    "metadata": {"labels": {"app": "webapp-app"}},
                    "spec": {"containers": [{"name": "webapp-app", "image": "nginx:1.27.4"}]},
                },
            },
        },
    ])
    validate = textwrap.dedent(
        f"""\
        #!/bin/bash
        set -euo pipefail
        if kubectl get namespace webapp-prod >/dev/null 2>&1 && kubectl get deployment webapp-app -n webapp-prod >/dev/null 2>&1; then
          echo "✅ PASS: target namespace exists and app is deployed"
          exit 0
        fi
        echo "❌ FAIL: ArgoCD proxy target namespace or app is missing"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_multi_env_config(level: dict) -> dict:
    broken = dump_resources([
        configmap("env-config", {"LOG_LEVEL": "debug"}),
        deployment("multi-env-app", "nginx:1.27.4", replicas=1, resources={"requests": {"cpu": "100m", "memory": "64Mi"}}),
    ])
    solution = dump_resources([
        configmap("env-config", {"LOG_LEVEL": "info"}),
        deployment(
            "multi-env-app",
            "nginx:1.27.4",
            replicas=3,
            resources={"requests": {"cpu": "100m", "memory": "64Mi"}, "limits": {"cpu": "500m", "memory": "512Mi"}},
        ),
    ])
    validate = generic_validate(
        """
        LEVEL=$(kubectl get configmap env-config -n "$NS" -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null || true)
        REPLICAS=$(kubectl get deployment multi-env-app -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
        CPU=$(kubectl get deployment multi-env-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)
        if [ "$LEVEL" = "info" ] && [ "$REPLICAS" = "3" ] && [ "$CPU" = "500m" ]; then
          echo "✅ PASS: Production overlay proxy looks correct"
          exit 0
        fi
        echo "❌ FAIL: log_level='$LEVEL' replicas='$REPLICAS' cpu='$CPU'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_graceful_shutdown(level: dict) -> dict:
    broken = dump_resources([deployment("graceful-app", "nginx:1.27.4")])
    solution = dump_resources([
        deployment(
            "graceful-app",
            "nginx:1.27.4",
            lifecycle={"preStop": {"exec": {"command": ["/bin/sh", "-c", "sleep 15"]}}},
            termination_grace_period=60,
        )
    ])
    validate = generic_validate(
        """
        PRESTOP=$(kubectl get deployment graceful-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}' 2>/dev/null || true)
        GRACE=$(kubectl get deployment graceful-app -n "$NS" -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}' 2>/dev/null || true)
        if [ "$PRESTOP" = "sleep 15" ] && [ "$GRACE" = "60" ]; then
          echo "✅ PASS: Graceful shutdown hooks are in place"
          exit 0
        fi
        echo "❌ FAIL: preStop='$PRESTOP' grace='$GRACE'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_external_secrets(level: dict) -> dict:
    broken = dump_resources([secret("app-secret", {"username": "plain-user", "password": "plain-pass"})])
    solution = dump_resources([
        {
            "apiVersion": "v1",
            "kind": "Secret",
            "metadata": {
                "name": "app-secret",
                "namespace": NS,
                "annotations": {"managed-by": "external-secrets"},
            },
            "type": "Opaque",
            "stringData": {"username": "app-user", "password": "rotated-pass"},
        }
    ])
    validate = generic_validate(
        """
        MANAGED=$(kubectl get secret app-secret -n "$NS" -o jsonpath='{.metadata.annotations.managed-by}' 2>/dev/null || true)
        if [ "$MANAGED" = "external-secrets" ]; then
          echo "✅ PASS: Secret is now managed by the External Secrets proxy"
          exit 0
        fi
        echo "❌ FAIL: Secret annotation managed-by='$MANAGED'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_cluster_autoscaler(level: dict) -> dict:
    broken = dump_resources([
        deployment(
            "cluster-autoscaler",
            "registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.0",
            args=["--node-group-auto-discovery=asg:tag=wrong-group"],
        )
    ])
    solution = dump_resources([
        deployment(
            "cluster-autoscaler",
            "registry.k8s.io/autoscaling/cluster-autoscaler:v1.30.0",
            args=["--node-group-auto-discovery=asg:tag=kind-worker"],
        )
    ])
    validate = generic_validate(
        """
        ARG=$(kubectl get deployment cluster-autoscaler -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].args[0]}' 2>/dev/null || true)
        if echo "$ARG" | grep -q 'kind-worker'; then
          echo "✅ PASS: Cluster Autoscaler proxy points to the correct node group"
          exit 0
        fi
        echo "❌ FAIL: autoscaler arg is '$ARG'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_production_runbook(level: dict) -> dict:
    broken = dump_resources([
        deployment("runbook-app", "nginx:1.27.4", replicas=1),
        {
            "apiVersion": "batch/v1",
            "kind": "Job",
            "metadata": {"name": "db-migration", "namespace": NS},
            "spec": {
                "template": {
                    "spec": {
                        "restartPolicy": "Never",
                        "containers": [{"name": "db-migration", "image": "busybox:missing", "command": ["/bin/sh", "-c", "exit 1"]}],
                    }
                }
            },
        },
    ])
    solution = dump_resources([
        deployment("runbook-app", "nginx:1.27.4", replicas=1),
        {
            "apiVersion": "batch/v1",
            "kind": "Job",
            "metadata": {"name": "db-migration", "namespace": NS},
            "spec": {
                "template": {
                    "spec": {
                        "restartPolicy": "Never",
                        "containers": [
                            {
                                "name": "db-migration",
                                "image": "busybox:1.36",
                                "command": ["/bin/sh", "-c", "echo migration complete"],
                                "env": [{"name": "DATABASE_URL", "value": "postgres://db/app"}],
                            }
                        ],
                    }
                }
            },
        },
    ])
    validate = generic_validate(
        """
        IMAGE=$(kubectl get job db-migration -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
        ENV=$(kubectl get job db-migration -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].env[0].name}' 2>/dev/null || true)
        if [ "$IMAGE" = "busybox:1.36" ] && [ "$ENV" = "DATABASE_URL" ]; then
          echo "✅ PASS: Migration job is correctly configured"
          exit 0
        fi
        echo "❌ FAIL: image='$IMAGE' env='$ENV'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_grand_finale(level: dict) -> dict:
    broken = dump_resources([
        deployment(
            "grand-finale-app",
            "nginx:latest",
            replicas=1,
            readiness=None,
            resources={"requests": {"cpu": "100m", "memory": "64Mi"}},
        ),
        {
            "apiVersion": "policy/v1",
            "kind": "PodDisruptionBudget",
            "metadata": {"name": "grand-finale-pdb", "namespace": NS},
            "spec": {"minAvailable": 3, "selector": {"matchLabels": {"app": "grand-finale-app"}}},
        },
    ])
    solution = dump_resources([
        deployment(
            "grand-finale-app",
            "nginx:1.27.4",
            replicas=3,
            readiness={"httpGet": {"path": "/", "port": 80}, "initialDelaySeconds": 5, "periodSeconds": 5},
            lifecycle={"preStop": {"exec": {"command": ["/bin/sh", "-c", "sleep 15"]}}},
            termination_grace_period=60,
            resources={"requests": {"cpu": "100m", "memory": "64Mi"}, "limits": {"cpu": "500m", "memory": "512Mi"}},
        ),
        {
            "apiVersion": "policy/v1",
            "kind": "PodDisruptionBudget",
            "metadata": {"name": "grand-finale-pdb", "namespace": NS},
            "spec": {"minAvailable": 1, "selector": {"matchLabels": {"app": "grand-finale-app"}}},
        },
    ])
    validate = generic_validate(
        """
        IMAGE=$(kubectl get deployment grand-finale-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
        READY=$(kubectl get deployment grand-finale-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
        PDB=$(kubectl get pdb grand-finale-pdb -n "$NS" -o jsonpath='{.spec.minAvailable}' 2>/dev/null || true)
        if [ "$IMAGE" = "nginx:1.27.4" ] && [ "$READY" = "/" ] && [ "$PDB" = "1" ]; then
          echo "✅ PASS: Production proxy stack is repaired"
          exit 0
        fi
        echo "❌ FAIL: image='$IMAGE' readiness='$READY' pdb='$PDB'"
        exit 1
        """
    )
    return {"broken": broken, "solution": solution, "validate": validate}


def build_all_levels() -> list[Path]:
    clean_module_directories()
    created: list[Path] = []
    for module_file in sorted(MODULES_DIR.glob("*/MODULE_DESCRIPTION.txt")):
        for level in parse_module_description(module_file):
            target = module_file.parent / level["dir_name"]
            build_level(target, level, build_custom_level(level))
            created.append(target)
    return created


def generate_registry() -> Path:
    """Scan all module/level directories and write levels.json (#12)."""
    import re as _re
    import yaml as _yaml
    from datetime import datetime

    def sort_key(name: str) -> tuple[int, str]:
        m = _re.search(r"(\d+)", name)
        return (int(m.group(1)) if m else 9999, name)

    modules_out = []
    for module_dir in sorted((p for p in MODULES_DIR.iterdir() if p.is_dir()), key=lambda p: sort_key(p.name)):
        levels_out = []
        for level_dir in sorted((p for p in module_dir.iterdir() if p.is_dir()), key=lambda p: sort_key(p.name)):
            mission_file = level_dir / "mission.yaml"
            if not mission_file.exists():
                continue
            try:
                mission = _yaml.safe_load(mission_file.read_text(encoding="utf-8")) or {}
            except Exception:
                mission = {}
            levels_out.append({
                "id": f"{module_dir.name}/{level_dir.name}",
                "name": level_dir.name,
                "path": f"modules/{module_dir.name}/{level_dir.name}",
                "mission": mission,
            })
        if levels_out:
            modules_out.append({"name": module_dir.name, "levels": levels_out})

    registry = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "level_count": sum(len(w["levels"]) for w in modules_out),
        "modules": modules_out,
    }
    out_path = ROOT / "levels.json"
    out_path.write_text(json.dumps(registry, indent=2), encoding="utf-8")
    return out_path


def main() -> int:
    created = build_all_levels()
    print(f"Generated {len(created)} levels under {MODULES_DIR}")
    registry_path = generate_registry()
    print(f"Registry written to {registry_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
