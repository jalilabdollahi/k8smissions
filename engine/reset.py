#!/usr/bin/env python3
"""Build a level's broken state on a clean cluster.

Every level starts from the same baseline, whatever earlier levels (or the
player) left behind:
  - the k8smissions namespace and every namespace labelled k8smissions/managed
    are deleted (stuck finalizers are stripped);
  - cluster-scoped and namespaced objects labelled k8smissions/managed are
    deleted, plus any objects a level lists under "cleanup" in mission.yaml;
  - nodes are uncordoned, level taints and level labels are removed.
Then the level's add-ons are ensured, setup.sh runs, broken.yaml is applied,
and everything those files created is labelled k8smissions/managed=true.

scripts/test_levels.py uses these same functions, so what is tested is what
the player gets.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

try:
    from engine.addons import PROTECTED_NAMESPACES, ensure as ensure_addons
except ModuleNotFoundError:  # run as a script from engine/
    from addons import PROTECTED_NAMESPACES, ensure as ensure_addons

NAMESPACE = "k8smissions"
LABEL = "k8smissions/managed"
SANDBOX_FILE = Path.home() / ".k8smissions" / "sandbox" / "manifest.yaml"

NAMESPACED_KINDS = ",".join([
    "deployments", "statefulsets", "daemonsets", "replicasets", "pods", "jobs", "cronjobs",
    "services", "configmaps", "secrets", "serviceaccounts", "roles", "rolebindings",
    "networkpolicies", "persistentvolumeclaims", "ingresses", "poddisruptionbudgets",
    "horizontalpodautoscalers", "resourcequotas", "limitranges", "leases",
])
# Node labels that belong to Kubernetes/kind itself; everything else is level state.
KEEP_NODE_LABEL = re.compile(r"(^|\.|/)(kubernetes\.io|k8s\.io)/|^ingress-ready$")
KEEP_TAINT = {"node-role.kubernetes.io/control-plane"}
STANDARD_RESOURCES = {"cpu", "memory", "pods", "ephemeral-storage"}


def _run(args, cwd=None, check=True, timeout=180, env=None):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=False, timeout=timeout,
                       env={**os.environ, "NS": NAMESPACE, **(env or {})})
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(str(a) for a in args[:4])} failed: {(r.stderr or r.stdout).strip()[-500:]}")
    return r


def _quiet(args, timeout=120):
    return _run(args, check=False, timeout=timeout)


def load_mission(level_path: Path) -> dict:
    return json.loads((level_path / "mission.yaml").read_text(encoding="utf-8"))


def _all_cleanup_entries(repo_root: Path) -> list[str]:
    """Objects levels declare they create outside the label (e.g. made by the player)."""
    out: set[str] = set()
    for f in (repo_root / "modules").glob("*/*/mission.yaml"):
        try:
            out.update(json.loads(f.read_text(encoding="utf-8")).get("cleanup", []))
        except Exception:
            pass
    return sorted(out)


def _cluster_scoped_kinds() -> list[str]:
    r = _quiet(["kubectl", "api-resources", "--namespaced=false", "--verbs=list,delete", "-o", "name"])
    skip = {"nodes", "namespaces", "componentstatuses"}
    kinds = [k for k in r.stdout.split() if k not in skip and not k.endswith(".metrics.k8s.io")]
    # webhooks first, so a broken webhook can't block the other deletions
    return sorted(kinds, key=lambda k: 0 if "webhookconfiguration" in k else 1)


def _strip_finalizers_in_namespace(ns: str) -> None:
    r = _quiet(["kubectl", "api-resources", "--namespaced=true", "--verbs=list", "-o", "name"])
    for kind in r.stdout.split():
        objs = _quiet(["kubectl", "get", kind, "-n", ns, "-o", "name"], timeout=20).stdout.split()
        for obj in objs:
            _quiet(["kubectl", "patch", obj, "-n", ns, "--type=merge", "-p", '{"metadata":{"finalizers":null}}'], timeout=20)


def _delete_namespaces(names: list[str], timeout: int = 60) -> None:
    for ns in names:
        _quiet(["kubectl", "delete", "pods", "--all", "-n", ns, "--grace-period=0", "--force"], timeout=60)
    if names:
        _quiet(["kubectl", "delete", "namespace", *names, "--ignore-not-found", "--wait=false"])
    deadline = time.time() + timeout
    stripped = False
    while True:
        alive = [ns for ns in names if _quiet(["kubectl", "get", "namespace", ns], timeout=20).returncode == 0]
        if not alive:
            return
        if time.time() > deadline:
            if stripped:
                raise RuntimeError(f"namespaces still terminating: {alive}")
            for ns in alive:
                _strip_finalizers_in_namespace(ns)
            stripped, deadline = True, time.time() + timeout
        time.sleep(2)


def _reset_nodes() -> None:
    r = _quiet(["kubectl", "get", "nodes", "-o", "json"])
    if r.returncode != 0:
        return
    for node in json.loads(r.stdout).get("items", []):
        name = node["metadata"]["name"]
        if node["spec"].get("unschedulable"):
            _quiet(["kubectl", "uncordon", name])
        for t in node["spec"].get("taints", []) or []:
            if t["key"] not in KEEP_TAINT and not t["key"].startswith("node.kubernetes.io/"):
                _quiet(["kubectl", "taint", "node", name, f"{t['key']}:{t['effect']}-"])
        drop = [f"{k}-" for k in node["metadata"].get("labels", {}) if not KEEP_NODE_LABEL.search(k)]
        if drop:
            _quiet(["kubectl", "label", "node", name, *drop])
        # extended resources a level advertised by patching node status
        ops = [{"op": "remove", "path": f"/status/{field}/{k.replace('~', '~0').replace('/', '~1')}"}
               for field in ("capacity", "allocatable")
               for k in (node.get("status", {}).get(field) or {})
               if k not in STANDARD_RESOURCES and not k.startswith("hugepages-")]
        if ops:
            _quiet(["kubectl", "patch", "node", name, "--subresource=status", "--type=json", "-p", json.dumps(ops)])


def cleanup_all(repo_root: Path) -> None:
    """Return the cluster to the baseline. Safe to call at any time."""
    sel = f"{LABEL}=true"
    kinds = _cluster_scoped_kinds()
    if kinds:
        _quiet(["kubectl", "delete", ",".join(kinds), "-l", sel, "--ignore-not-found", "--wait=false"])
    extra = _all_cleanup_entries(repo_root)
    if extra:
        _quiet(["kubectl", "delete", *extra, "--ignore-not-found", "--wait=false"])
    _quiet(["kubectl", "delete", NAMESPACED_KINDS, "-A", "-l", sel, "--ignore-not-found", "--wait=false"])

    r = _quiet(["kubectl", "get", "namespaces", "-l", sel, "-o", "jsonpath={.items[*].metadata.name}"])
    namespaces = sorted(({NAMESPACE} | set(r.stdout.split())) - PROTECTED_NAMESPACES)
    _delete_namespaces(namespaces)

    # objects with finalizers that a deleted controller will never clear
    for kind in ["customresourcedefinitions", "persistentvolumes"]:
        objs = _quiet(["kubectl", "get", kind, "-l", sel, "-o", "name"]).stdout.split()
        for obj in objs:
            _quiet(["kubectl", "patch", obj, "--type=merge", "-p", '{"metadata":{"finalizers":null}}'])
    _reset_nodes()


def _label_manifest(path: Path) -> None:
    _quiet(["kubectl", "label", "-f", str(path), f"{LABEL}=true", "--overwrite"], timeout=60)


def apply_broken_state(level_path: Path, log=print) -> None:
    mission = load_mission(level_path)
    ensure_addons(mission.get("requires", []), log=log)
    _run(["kubectl", "create", "namespace", NAMESPACE], check=False)
    _quiet(["kubectl", "label", "namespace", NAMESPACE, f"{LABEL}=true", "--overwrite"])

    if (level_path / "setup.sh").exists():
        _run(["bash", "setup.sh"], cwd=level_path, timeout=300)
    if (level_path / "setup.yaml").exists():
        _label_manifest(level_path / "setup.yaml")
    broken = level_path / "broken.yaml"
    if broken.exists():
        _run(["kubectl", "apply", "-f", "broken.yaml"], cwd=level_path)
        _label_manifest(broken)
        SANDBOX_FILE.parent.mkdir(parents=True, exist_ok=True)
        SANDBOX_FILE.write_text(broken.read_text(encoding="utf-8"), encoding="utf-8")


def prepare_level(repo_root: Path, level_path: Path, log=print) -> None:
    """Clean the cluster and apply this level's broken state."""
    cleanup_all(repo_root)
    apply_broken_state(level_path, log=log)


def reset_current_level(repo_root: Path, level_path: Path) -> bool:
    try:
        prepare_level(repo_root, level_path)
    except Exception as exc:  # pragma: no cover - CLI path
        print(f"Reset failed: {exc}", file=sys.stderr)
        return False
    return True


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 engine/reset.py <level-path>")
        return 1
    repo_root = Path(__file__).resolve().parent.parent
    return 0 if reset_current_level(repo_root, Path(sys.argv[1]).resolve()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
