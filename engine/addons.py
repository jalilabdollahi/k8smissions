#!/usr/bin/env python3
"""Cluster add-ons that some levels need (mission.yaml "requires": [...]).

Each add-on is installed once, from a pinned upstream release, and stays in
its own namespace. Level cleanup never touches add-on namespaces.
Run directly to install one or more: python3 engine/addons.py tekton argocd
"""

from __future__ import annotations

import subprocess
import sys

METRICS_SERVER = "v0.9.1"
INGRESS_NGINX = "controller-v1.15.1"
TEKTON = "v1.18.0"
ARGOCD = "v3.6.1"

ADDONS: dict[str, dict] = {
    "metrics-server": {
        "check": ["kubectl", "get", "deployment", "metrics-server", "-n", "kube-system"],
        "install": [
            ["kubectl", "apply", "-f", f"https://github.com/kubernetes-sigs/metrics-server/releases/download/{METRICS_SERVER}/components.yaml"],
            # kind's kubelets use self-signed serving certs
            ["kubectl", "patch", "deployment", "metrics-server", "-n", "kube-system", "--type=json", "-p",
             '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'],
            ["kubectl", "rollout", "status", "deployment/metrics-server", "-n", "kube-system", "--timeout=180s"],
        ],
        "namespaces": [],
    },
    "ingress-nginx": {
        "check": ["kubectl", "get", "deployment", "ingress-nginx-controller", "-n", "ingress-nginx"],
        "install": [
            ["kubectl", "label", "node", "--all", "ingress-ready=true", "--overwrite"],
            ["kubectl", "apply", "-f", f"https://raw.githubusercontent.com/kubernetes/ingress-nginx/{INGRESS_NGINX}/deploy/static/provider/kind/deploy.yaml"],
            ["kubectl", "rollout", "status", "deployment/ingress-nginx-controller", "-n", "ingress-nginx", "--timeout=240s"],
        ],
        "namespaces": ["ingress-nginx"],
    },
    "tekton": {
        "check": ["kubectl", "get", "deployment", "tekton-pipelines-controller", "-n", "tekton-pipelines"],
        "install": [
            ["kubectl", "apply", "-f", f"https://infra.tekton.dev/tekton-releases/pipeline/previous/{TEKTON}/release.yaml"],
            ["kubectl", "rollout", "status", "deployment/tekton-pipelines-controller", "-n", "tekton-pipelines", "--timeout=240s"],
            ["kubectl", "rollout", "status", "deployment/tekton-pipelines-webhook", "-n", "tekton-pipelines", "--timeout=240s"],
        ],
        "namespaces": ["tekton-pipelines", "tekton-pipelines-resolvers"],
    },
    "argocd": {
        "check": ["kubectl", "get", "statefulset", "argocd-application-controller", "-n", "argocd"],
        "install": [
            ["kubectl", "create", "namespace", "argocd"],
            ["kubectl", "apply", "--server-side", "-n", "argocd", "-f", f"https://raw.githubusercontent.com/argoproj/argo-cd/{ARGOCD}/manifests/core-install.yaml"],
            ["kubectl", "rollout", "status", "statefulset/argocd-application-controller", "-n", "argocd", "--timeout=300s"],
            ["kubectl", "rollout", "status", "deployment/argocd-repo-server", "-n", "argocd", "--timeout=300s"],
        ],
        "namespaces": ["argocd"],
    },
}

PROTECTED_NAMESPACES = {"kube-system", "kube-public", "kube-node-lease", "default", "local-path-storage"} | {
    ns for a in ADDONS.values() for ns in a["namespaces"]
}


def is_installed(name: str) -> bool:
    return subprocess.run(ADDONS[name]["check"], capture_output=True, check=False).returncode == 0


def ensure(names: list[str], log=print) -> None:
    for name in names:
        if name not in ADDONS:
            raise ValueError(f"unknown add-on '{name}' (known: {', '.join(ADDONS)})")
        if is_installed(name):
            continue
        log(f"Installing add-on {name} (first time only, can take a few minutes)...")
        for step in ADDONS[name]["install"]:
            r = subprocess.run(step, capture_output=True, text=True, check=False, timeout=420)
            if r.returncode != 0 and "AlreadyExists" not in r.stderr and "already exists" not in r.stderr:
                raise RuntimeError(f"add-on {name}: {' '.join(step[:3])} failed: {r.stderr.strip()[-400:]}")


if __name__ == "__main__":
    ensure(sys.argv[1:] or list(ADDONS))
