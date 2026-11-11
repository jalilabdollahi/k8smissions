## What was broken

The platform team did their part: ConfigMap `pricing-config` holds `TAX_RATE: "0.20"`. But the `pricing` pods take that value through `envFrom`, which copies the ConfigMap into environment variables once, when each container starts. The pods had started before the edit, so they went on answering with 0.19.

## The evidence

`kubectl get cm pricing-config -o yaml` and `kubectl describe deploy pricing` both looked correct, and nothing restarted or failed. The disagreement only shows when you compare the object with the process: `kubectl exec deploy/pricing -- env` printed `TAX_RATE=0.19`, and so did the HTTP answer.

## Why Kubernetes behaved this way

A process's environment is fixed at exec time; no controller can change it afterwards. Kubernetes does not restart pods when a ConfigMap they referenced changes, either. A ConfigMap mounted as a volume is different: the kubelet refreshes the files within about a minute, but the application still has to re-read them.

## The fix

Restart the pods from the unchanged Deployment with `kubectl rollout restart`. It performs a normal rolling update, so the Service keeps answering throughout, and the new pods read the current ConfigMap.

## In production

Make config changes and restarts one step: put a hash of the ConfigMap into the pod template annotations (Helm and Kustomize can do this for you), or use a tool such as Reloader. After editing a ConfigMap, always verify from inside a pod.

## Commands worth remembering

- `kubectl exec deploy/<name> -- env | grep <KEY>`
- `kubectl rollout restart deployment/<name>`
- `kubectl rollout status deployment/<name>`
