## What went wrong

The migration Job has `image: busybox:missing` — a tag that doesn't exist — and `command: ['exit 1']` — which always exits with failure code 1. With `restartPolicy: Never`, each failure creates a new pod attempt until `backoffLimit` is reached, at which point the Job enters `Failed` state.

## Fix

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  namespace: k8smissions
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: db-migration
        image: busybox:1.36
        command:
        - /bin/sh
        - -c
        - echo migration complete
        env:
        - name: DATABASE_URL
          value: postgres://db/app
```

## Why this matters

The safe production runbook for schema migrations:
1. Scale down the Deployment to 0 replicas (`kubectl scale deployment runbook-app --replicas=0`)
2. Apply and wait for the migration Job (`kubectl wait --for=condition=complete job/db-migration`)
3. Scale the Deployment back up

Skipping step 1 risks the old application code running against a partially migrated schema. Jobs with `restartPolicy: Never` and a reasonable `backoffLimit` (default: 6) are the standard pattern — each attempt gets a fresh pod, and the Job tracks completion vs. failure independently of pod restarts.