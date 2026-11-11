#!/bin/bash
kubectl -n k8smissions logs -l tekton.dev/pipelineTask=canary-gate --tail=3
kubectl -n k8smissions get service checkout -o jsonpath='{.spec.selector}'; echo
kubectl -n k8smissions get endpoints checkout
kubectl -n k8smissions get pipeline release-checkout -o json |
  python3 -c '
import json, sys
p = json.load(sys.stdin)
for t in p["spec"]["tasks"]:
    if t["name"] == "deploy-canary":
        s = t["taskSpec"]["steps"][0]["script"]
        t["taskSpec"]["steps"][0]["script"] = s.replace("{app: checkout-canary,", "{app: checkout,")
    if t["name"] == "canary-gate":
        t["timeout"] = "45s"
for k in ("metadata",):
    p[k] = {"name": p[k]["name"]}
json.dump(p, sys.stdout)' |
  kubectl -n k8smissions apply -f -
