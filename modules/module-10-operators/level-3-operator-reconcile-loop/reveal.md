The operator is configured through the `WATCH_NAMESPACE` environment variable, fed from ConfigMap `operator-config` key `watch-namespace`, which is set to `staging`: an existing but empty namespace, so the operator lists nothing and has nothing to report. Point it at `k8smissions` and restart the pod, because environment variables are read only when a container starts:

```bash
kubectl -n k8smissions patch configmap operator-config --type=merge -p '{"data":{"watch-namespace":"k8smissions"}}'
kubectl -n k8smissions rollout restart deployment/webapp-operator
```

- The patch changes the source of the value.
- The restart makes the new pod read it; without it nothing changes.

Within a few seconds `site-a` and `site-b` get their Deployments and Services and move to `Ready`.
