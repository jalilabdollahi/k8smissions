## What was broken

Release 4.2 renamed the container port from `http` to `app-http`. Service `checkout` still had `targetPort: http`. A named targetPort is resolved per pod against that pod's `containerPort` names, so for 4.2 pods the lookup found nothing: the pods stayed Ready and listed as endpoints, but with no port to send traffic to. kube-proxy answered with a connection refusal.

## The evidence

`kubectl get endpoints checkout` showed three IPs, which looked healthy. The EndpointSlice YAML told the truth: addresses present, `ports` empty. Comparing `kubectl get svc checkout -o yaml` (`targetPort: http`) with the pod's container ports (`app-http`) pointed at the mismatch.

## Why Kubernetes behaves this way

Names exist so that a Service survives container port number changes, and so that pods in one rollout can even expose different numbers under the same name. The cost is that the name is a contract between Service and pod template. Nothing validates it, and readiness probes do not exercise the Service path, so the rollout went through green.

## The fix

Change the Service to the new name (or to the number 8080). Rolling back the Deployment restores traffic but undoes the release, which is why the check insists on 4.2 answering.

## In production

Treat port names as API: change the pod template and the Service in the same commit, and smoke-test through the Service after a rollout. During a transition you can keep both: pods of the old and new versions can use different numbers behind the same name.

## Commands worth remembering

- `kubectl get endpointslices -l kubernetes.io/service-name=<svc> -o yaml`
- `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].ports}'`
- `kubectl rollout history deploy/<name>`
