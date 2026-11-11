#!/bin/bash
NS=k8smissions
# Fault 1: the shared library default of 90 MB cannot fit in 64Mi. All three read it through envFrom.
kubectl -n $NS patch cm lib-defaults --type=merge -p '{"data":{"CACHE_MB":"24"}}'
# Fault 2: svc-gamma's 40 MB spool sits in a memory-backed emptyDir, which is charged to the container.
kubectl -n $NS patch deploy svc-gamma --type=json -p='[{"op":"remove","path":"/spec/template/spec/volumes/1/emptyDir/medium"}]'
# envFrom is read at container start: restart the other two so they pick up the new value.
kubectl -n $NS rollout restart deploy/svc-alpha deploy/svc-beta
for s in alpha beta gamma; do kubectl -n $NS rollout status deploy/svc-$s --timeout=120s; done
