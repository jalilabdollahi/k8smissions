#!/bin/bash
NS=k8smissions
# Fault 1: auth stamps tokens with its local wall clock (TZ=PST8) while api reads them as UTC.
kubectl -n $NS set env deploy/auth TZ-
# Fault 2: 5 second tokens with no leeway; give clients room.
kubectl -n $NS set env deploy/auth TOKEN_TTL_SECONDS=300
kubectl -n $NS set env deploy/api LEEWAY_SECONDS=30
# Fault 3: api verifies with the pre-rotation key; copy the current key over.
key=$(kubectl -n $NS get secret auth-signing -o jsonpath='{.data.key}')
kubectl -n $NS patch secret api-verify --type=merge -p "{\"data\":{\"key\":\"$key\"}}"
kubectl -n $NS rollout restart deploy/api
kubectl -n $NS rollout status deploy/auth --timeout=120s
kubectl -n $NS rollout status deploy/api --timeout=120s
