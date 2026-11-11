## What was broken

`pay-restricted` enforces Pod Security Admission at the `restricted` level. The Deployment's pod template set none of the hardening the profile requires, so every pod was refused at admission: no pods, no Pending state, nothing to describe. The init container `prepare` (busybox, running as root) violated the same rules as the app container.

## Evidence

`kubectl describe rs` shows `FailedCreate ... violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (containers "prepare", "web" ...), unrestricted capabilities ..., runAsNonRoot != true ..., seccompProfile ...`. The message lists all violations and the containers that cause each, so one read tells you the whole task.

## Why Kubernetes behaved this way

PSA is an admission controller: it judges the pod spec when the pod is created, and the ReplicaSet controller records the rejection as an event. It checks every container, init and ephemeral ones included. `runAsNonRoot` and `seccompProfile` may be set at pod level and inherited; `allowPrivilegeEscalation` and `capabilities.drop` must be set per container. `runAsNonRoot` needs a numeric user, either from the image or `runAsUser`.

## The fix

Add the pod-level and container-level `securityContext` fields. The namespace labels stay as they are: lowering to `baseline` would also make the pods start, and defeat the policy.

## In production

Use `warn` and `audit` labels before turning on `enforce`, and `kubectl apply --dry-run=server` in CI to see violations early. Pick images that run as non-root by design.

## Commands worth remembering

- `kubectl describe rs <name>` for admission denials
- `kubectl get ns <ns> --show-labels`
- `kubectl label ns <ns> pod-security.kubernetes.io/warn=restricted` to preview
