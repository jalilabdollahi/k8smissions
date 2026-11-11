#!/bin/bash
# the retrier creates Jobs forever with no TTL: give them one before cleaning up
kubectl -n ci set env deploy/ci-retrier JOB_TTL_SECONDS=60
# the stuck run holds 600m of the 1 CPU quota and a Job slot
kubectl -n ci delete job flaky-suite
# completed retries from the retrier (keep the release Jobs)
kubectl -n ci delete job -l kind=retry
kubectl -n ci rollout status deploy/ci-retrier --timeout=90s
# the release driver retries every few seconds: wait for it to create the Job
for i in $(seq 1 40); do kubectl -n ci get job release-v42 >/dev/null 2>&1 && break; sleep 3; done
kubectl -n ci wait --for=condition=complete job/release-v42 --timeout=90s
