#!/usr/bin/env python3
"""Test levels end to end on an isolated kind cluster.

For every selected level:
  1. empty     clean cluster, nothing applied      -> validate.sh must FAIL
  2. broken    engine applies the broken state     -> validate.sh must FAIL (after settle_seconds)
  3. solved    solution.sh runs (as a player would) -> validate.sh must PASS within solve_timeout
  4. clean     engine cleanup                       -> no new cluster-scoped objects, nodes back to baseline

The cluster is separate from the game cluster: its kubeconfig lives in
~/.k8smissions/test/<name>.kubeconfig and is never merged into ~/.kube/config.

Usage:
  scripts/test_levels.py [filters...] [--cluster NAME] [--mirror] [--json out.json]
  scripts/test_levels.py --down --cluster NAME        # delete the test cluster
Filters match "module-3" or "module-3-networking/level-5" style substrings.
Exit code 1 if any level fails.
"""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MIRROR = "k8smissions-registry-mirror"


def sh(args, cwd=None, timeout=120, env=None):
    try:
        r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout,
                           env={**os.environ, "NS": "k8smissions", **(env or {})})
        return r.returncode, (r.stdout + r.stderr).strip()
    except subprocess.TimeoutExpired:
        return 124, f"timed out after {timeout}s"


def ensure_mirror(cluster: str) -> None:
    """Pull-through cache for docker.io shared by all test clusters (avoids rate limits)."""
    if sh(["docker", "inspect", MIRROR])[0] != 0:
        sh(["docker", "network", "create", "kind"])
        rc, out = sh(["docker", "run", "-d", "--name", MIRROR, "--network", "kind", "--restart=unless-stopped",
                      "-e", "REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io", "registry:2"])
        if rc:
            sys.exit(f"could not start registry mirror: {out}")
    hosts = ('server = "https://registry-1.docker.io"\n'
             f'[host."http://{MIRROR}:5000"]\n  capabilities = ["pull", "resolve"]\n')
    rc, nodes = sh(["kind", "get", "nodes", "--name", cluster])
    for node in nodes.split():
        sh(["docker", "exec", node, "sh", "-c",
            f"mkdir -p /etc/containerd/certs.d/docker.io && printf '%s' '{hosts}' > /etc/containerd/certs.d/docker.io/hosts.toml"])


def ensure_cluster(name: str, kubeconfig: Path, mirror: bool) -> None:
    rc, out = sh(["kind", "get", "clusters"])
    if name not in out.split():
        print(f"creating kind cluster {name} (kind-config.yaml)...", flush=True)
        kubeconfig.parent.mkdir(parents=True, exist_ok=True)
        rc, out = sh(["kind", "create", "cluster", "--name", name, "--config", str(REPO / "kind-config.yaml"),
                      "--kubeconfig", str(kubeconfig), "--wait", "180s"], timeout=600)
        if rc:
            sys.exit(f"kind create failed: {out[-800:]}")
    elif not kubeconfig.exists():
        sh(["kind", "export", "kubeconfig", "--name", name, "--kubeconfig", str(kubeconfig)])
    if mirror:
        ensure_mirror(name)


HEAVY_ADDONS = {"tekton", "argocd"}


def acquire_pool(names: list[str]):
    """Lock one of the named clusters; waits until one is free. The lock is held until exit."""
    d = Path.home() / ".k8smissions" / "test"
    d.mkdir(parents=True, exist_ok=True)
    waited = False
    while True:
        for name in names:
            f = open(d / f"{name}.lock", "w")
            try:
                fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return name, f
            except OSError:
                f.close()
        if not waited:
            print("all pool clusters busy, waiting...", flush=True)
            waited = True
        time.sleep(10)


def select_levels(filters: list[str]) -> list[Path]:
    reg = json.loads((REPO / "levels.json").read_text())
    paths = [REPO / lv["path"] for m in reg["modules"] for lv in m["levels"]]
    on_disk = sorted(p.parent for p in (REPO / "modules").glob("*/*/mission.yaml"))
    paths += [p for p in on_disk if p not in paths]  # levels missing from the registry still get tested
    if filters:
        paths = [p for p in paths if any(f in f"{p.parent.name}/{p.name}" for f in filters)]
    return paths


def validate(level: Path):
    return sh(["bash", "validate.sh"], cwd=level, timeout=90)


def snapshot():
    kinds = ("namespaces,clusterroles,clusterrolebindings,customresourcedefinitions,validatingwebhookconfigurations,"
             "mutatingwebhookconfigurations,persistentvolumes,storageclasses,priorityclasses,ingressclasses,"
             "validatingadmissionpolicies,validatingadmissionpolicybindings")
    rc, out = sh(["kubectl", "get", kinds, "-o", "name"])
    objs = set(out.splitlines()) if rc == 0 else set()
    rc, out = sh(["kubectl", "get", "nodes", "-o", "json"])
    nodes = []
    for n in (json.loads(out).get("items", []) if rc == 0 else []):
        taints = sorted(t["key"] for t in n["spec"].get("taints", []) or [] if not t["key"].startswith("node.kubernetes.io/"))
        nodes.append((n["metadata"]["name"], bool(n["spec"].get("unschedulable")), taints,
                      sorted(n["metadata"].get("labels", {}).items()), sorted((n.get("status", {}).get("capacity") or {}))))
    return objs, sorted(nodes)


def run_solution(level: Path):
    if (level / "solution.sh").exists():
        with tempfile.TemporaryDirectory() as tmp:  # the player has no level files
            return sh(["bash", str(level / "solution.sh")], cwd=tmp, timeout=420), "solution.sh"
    rc, out = sh(["kubectl", "apply", "-f", "solution.yaml"], cwd=level)
    if rc:
        rc, out = sh(["kubectl", "replace", "--force", "-f", "solution.yaml"], cwd=level, timeout=180)
    return (rc, out), "solution.yaml (legacy)"


def test_level(level: Path, reset, baseline) -> dict:
    mission = json.loads((level / "mission.yaml").read_text())
    rid = f"{level.parent.name}/{level.name}"
    res = {"level": rid, "problems": []}
    t0 = time.time()
    try:
        reset.cleanup_all(REPO)
        sh(["kubectl", "create", "namespace", "k8smissions"])
    except Exception as e:
        res["problems"].append(f"cleanup before level failed: {e}")
    rc, out = validate(level)
    if rc == 0:
        res["problems"].append("PASSES ON EMPTY CLUSTER: " + out[-200:])
    try:
        reset.apply_broken_state(level, log=lambda m: print("   " + m, flush=True))
    except Exception as e:
        res["problems"].append(f"BROKEN STATE FAILS TO APPLY: {str(e)[-300:]}")
    time.sleep(int(mission.get("settle_seconds", 15)))
    rc, out = validate(level)
    if rc == 0:
        res["problems"].append("PASSES WHEN BROKEN: " + out[-200:])
    elif rc == 124:
        res["problems"].append("validate.sh timed out on the broken state")

    (src, sout), how = run_solution(level)
    res["solution"] = how
    if src:
        res["problems"].append(f"{how} exited {src}: {sout[-300:]}")
    deadline = time.time() + int(mission.get("solve_timeout", 150))
    while True:
        rc, out = validate(level)
        if rc == 0 or time.time() > deadline:
            break
        time.sleep(5)
    if rc != 0:
        res["problems"].append("SOLUTION DOES NOT PASS: " + out[-300:])
    res["solve_seconds"] = round(time.time() - (deadline - int(mission.get("solve_timeout", 150))))

    try:
        reset.cleanup_all(REPO)
    except Exception as e:
        res["problems"].append(f"CLEANUP FAILS: {str(e)[-300:]}")
    objs, nodes = snapshot()
    leaked = sorted(objs - baseline[0])
    if leaked:
        res["problems"].append(f"LEAKS after cleanup (label them or list them in mission.yaml cleanup): {leaked}")
        for o in leaked:  # keep later levels isolated
            sh(["kubectl", "delete", o, "--ignore-not-found", "--wait=false"])
            sh(["kubectl", "patch", o, "--type=merge", "-p", '{"metadata":{"finalizers":null}}'])
    if nodes != baseline[1]:
        res["problems"].append("NODE STATE not restored after cleanup")
    res["seconds"] = round(time.time() - t0)
    return res


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("filters", nargs="*")
    ap.add_argument("--cluster", default="k8smissions-test")
    ap.add_argument("--mirror", action="store_true", help="use a local docker.io pull-through cache")
    ap.add_argument("--json", help="write results to this file")
    ap.add_argument("--down", action="store_true", help="delete the test cluster and exit")
    ap.add_argument("--pool", type=int, default=0,
                    help="share N clusters (k8sm-pool-1..N; levels needing tekton/argocd use k8sm-pool-cd) between authors")
    args = ap.parse_args()
    lock = None
    if args.pool and not args.down:
        # Argo CD + Tekton need ~1 GB more RAM, so levels that use them share one dedicated cluster.
        needs = {a for lv in select_levels(args.filters)
                 for a in json.loads((lv / "mission.yaml").read_text()).get("requires", [])}
        # light levels may also borrow the cd cluster when it is free
        names = ["k8sm-pool-cd"] if needs & HEAVY_ADDONS else [f"k8sm-pool-{i}" for i in range(1, args.pool + 1)] + ["k8sm-pool-cd"]
        args.cluster, lock = acquire_pool(names)
        print(f"using pool cluster {args.cluster}", flush=True)

    kubeconfig = Path.home() / ".k8smissions" / "test" / f"{args.cluster}.kubeconfig"
    if args.down:
        sh(["kind", "delete", "cluster", "--name", args.cluster], timeout=300)
        kubeconfig.unlink(missing_ok=True)
        print(f"deleted {args.cluster}")
        return 0
    ensure_cluster(args.cluster, kubeconfig, args.mirror)
    os.environ["KUBECONFIG"] = str(kubeconfig)  # inherited by every kubectl the engine and scripts run
    sys.path.insert(0, str(REPO))
    from engine import reset

    levels = select_levels(args.filters)
    sh(["kubectl", "wait", "--for=condition=Ready", "nodes", "--all", "--timeout=180s"], timeout=200)
    reset.cleanup_all(REPO)
    baseline = snapshot()
    results, failed = [], 0
    for level in levels:
        r = test_level(level, reset, baseline)
        results.append(r)
        ok = not r["problems"]
        failed += not ok
        print(f"{'PASS' if ok else 'FAIL'}  {r['level']}  ({r['seconds']}s)", flush=True)
        for p in r["problems"]:
            print(f"      - {p}", flush=True)
    print(f"\n{len(levels) - failed}/{len(levels)} levels pass")
    if args.json:
        Path(args.json).write_text(json.dumps(results, indent=1))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
