#!/bin/bash
NS=k8smissions
# immutable: the ConfigMap cannot be edited, so roll forward to a new name with the last good values (v41)
max=$(kubectl -n $NS get cm shop-config-v41 -o jsonpath='{.data.MAX_CONN}')
url=$(kubectl -n $NS get cm shop-config-v41 -o jsonpath='{.data.PRICING_URL}')
kubectl -n $NS create cm shop-config-v43 --from-literal=MAX_CONN="$max" --from-literal=PRICING_URL="$url"
# all three consumers: web (envFrom), worker (subPath files), CronJob (envFrom)
kubectl -n $NS patch deploy shop-web --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/envFrom/0/configMapRef/name","value":"shop-config-v43"}]'
kubectl -n $NS patch deploy shop-worker --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/1/configMap/name","value":"shop-config-v43"}]'
kubectl -n $NS patch cronjob shop-report --type=json \
  -p='[{"op":"replace","path":"/spec/jobTemplate/spec/template/spec/containers/0/envFrom/0/configMapRef/name","value":"shop-config-v43"}]'
kubectl -n $NS rollout status deploy/shop-web --timeout=120s
kubectl -n $NS rollout status deploy/shop-worker --timeout=120s
