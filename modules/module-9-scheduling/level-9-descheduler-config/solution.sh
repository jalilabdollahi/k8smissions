kubectl -n k8smissions get cronjob,job
last=$(kubectl -n k8smissions get jobs --sort-by=.metadata.creationTimestamp -o name | tail -1)
kubectl -n k8smissions logs "$last" | tail -20
kubectl -n k8smissions get configmap descheduler-policy -o jsonpath='{.data.policy\.yaml}'
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: descheduler-policy
  namespace: k8smissions
data:
  policy.yaml: |
    apiVersion: descheduler/v1alpha2
    kind: DeschedulerPolicy
    profiles:
    - name: rebalance
      pluginConfig:
      - name: LowNodeUtilization
        args:
          thresholds:
            cpu: 20
            memory: 20
            pods: 20
          targetThresholds:
            cpu: 50
            memory: 50
            pods: 50
          evictableNamespaces:
            exclude: ["kube-system", "local-path-storage"]
      plugins:
        balance:
          enabled:
          - LowNodeUtilization
YAML
kubectl -n k8smissions create job --from=cronjob/descheduler descheduler-manual
kubectl -n k8smissions wait --for=condition=complete job/descheduler-manual --timeout=120s
kubectl -n k8smissions logs job/descheduler-manual | grep -i evict | tail -5
kubectl -n k8smissions rollout status deploy/search-indexer --timeout=90s
kubectl -n k8smissions get pods -o wide
