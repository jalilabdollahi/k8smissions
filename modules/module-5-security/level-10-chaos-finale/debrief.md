## What was broken

Four independent guard-rail problems stacked on top of each other, and each one hid the next: the pod spec violated the `restricted` Pod Security level, so no pod was created; once admitted, the quota refused pods without CPU and memory limits; once running, the app's Role lacked the `get` verb and the pod crashed on a 403; and finally the database policy admitted a label (`settlement-api`) that the app does not carry.

## Evidence

Each layer left its trace somewhere different. Admission failures (PSA, then quota) appear as `FailedCreate` events on the ReplicaSet and never as pods. A 403 is in the container log and names the user, verb and resource. A NetworkPolicy block has no error at all, only a TCP timeout, and the proof is in the policy's selectors versus `get pods --show-labels`.

## Why Kubernetes behaved this way

Pod creation passes through admission plugins in a fixed order, and a request stops at the first denial. PodSecurity runs before ResourceQuota, so the quota demand only shows after the PSA problem is fixed. RBAC applies per request at runtime, so a pod can start and then fail. NetworkPolicy is an allow-list for the pods it selects; a pod that matches no allow rule is silently dropped.

## The fix

Fix them in the order the symptoms appear and keep every guard rail: security contexts, limits within the quota, one extra verb on the Role, and a corrected selector in the policy.

## In production

Treat a stuck rollout as a pipeline: admission, scheduling, start-up, runtime permissions, network. After each fix, re-read the ReplicaSet events before you touch anything else. Relaxing a namespace label or deleting a policy would have made every symptom vanish at once, and removed the controls.

## Commands worth remembering

- `kubectl describe rs <name>` (admission errors live here)
- `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>`
- `kubectl get netpol -o yaml` next to `kubectl get pods --show-labels`
