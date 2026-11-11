#!/bin/bash
NS=k8smissions
# auth: the volume has key JWT_SECRET, the app reads the file jwt-secret
v=$(kubectl -n $NS get secret auth-secrets -o jsonpath='{.data.JWT_SECRET}')
kubectl -n $NS patch secret auth-secrets -p "{\"data\":{\"jwt-secret\":\"$v\"}}"
# users-cache: the seed ConfigMap is called users-seed
kubectl -n $NS patch deploy users-cache --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/1/configMap/name","value":"users-seed"}]'
# users-cache Service: the container listens on 8080
kubectl -n $NS patch svc users-cache --type=json \
  -p='[{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]'
kubectl -n $NS rollout status deploy/users-cache --timeout=90s
kubectl -n $NS rollout restart deploy/auth
kubectl -n $NS rollout status deploy/auth --timeout=90s
kubectl -n $NS rollout status deploy/gateway --timeout=90s
