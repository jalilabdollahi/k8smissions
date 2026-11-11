#!/bin/bash
NS=k8smissions
# both references to the retired host: the app and the init container
kubectl -n $NS set image deploy/storefront storefront=hashicorp/http-echo:1.0 schema-check=busybox:1.36
# the sidecar's image is on Docker Hub, not on the nodes: it must be allowed to pull
kubectl -n $NS patch deploy storefront --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/1/imagePullPolicy","value":"IfNotPresent"}]'
kubectl -n $NS rollout status deploy/storefront --timeout=120s
