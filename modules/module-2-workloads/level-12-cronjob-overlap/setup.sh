#!/bin/bash
# The CronJob and four runs that are already piling up. `create job --from`
# sets the ownerReference to the CronJob, exactly like a scheduled run.
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: data-processor
spec:
  schedule: "* * * * *"
  concurrencyPolicy: Allow
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  jobTemplate:
    metadata:
      labels: {app: data-processor}
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels: {app: data-processor}
        spec:
          restartPolicy: Never
          terminationGracePeriodSeconds: 1
          containers:
          - name: processor
            image: busybox:1.36
            command: ["sh", "-c", "echo crunching the nightly batch; sleep 180; echo done"]
            resources:
              requests: {cpu: 10m, memory: 16Mi}
YAML
for i in 1 2 3 4; do
  kubectl -n "$NS" create job "data-processor-seed-$i" --from=cronjob/data-processor
done
kubectl -n "$NS" wait --for=condition=Ready pod -l app=data-processor --timeout=90s
