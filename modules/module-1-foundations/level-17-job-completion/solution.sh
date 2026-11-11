kubectl -n k8smissions get job nightly-import
kubectl -n k8smissions describe job nightly-import | grep -A3 -i conditions
kubectl -n k8smissions get job nightly-import -o yaml | grep -n activeDeadlineSeconds
kubectl -n k8smissions delete job nightly-import
kubectl apply -f - <<'YAML'
apiVersion: batch/v1
kind: Job
metadata:
  name: nightly-import
  namespace: k8smissions
spec:
  completions: 3
  parallelism: 1
  completionMode: Indexed
  backoffLimit: 2
  activeDeadlineSeconds: 300
  template:
    metadata:
      labels:
        app: nightly-import
    spec:
      restartPolicy: Never
      containers:
      - name: import
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          shard=$((JOB_COMPLETION_INDEX + 1))
          echo "importing shard $shard of 3"
          sleep 12
          echo "shard $shard ok"
YAML
kubectl -n k8smissions wait --for=condition=complete job/nightly-import --timeout=100s
