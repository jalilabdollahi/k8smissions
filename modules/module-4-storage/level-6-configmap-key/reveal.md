# Reveal

The `settings` volume selects the key `settings.yaml` from `app-config`, but the ConfigMap only has `app.yaml` since the refactor. The kubelet cannot build the volume, so the container is never created.

1. `kubectl describe pod -l app=web-app -n k8smissions` shows `configmap references non-existent config key: settings.yaml`.
2. `kubectl get configmap app-config -n k8smissions -o yaml` shows the key is `app.yaml`.
3. Point the item at the real key:

   ```bash
   kubectl patch deploy/web-app --namespace k8smissions --type=json \
     -p '[{"op":"replace","path":"/spec/template/spec/volumes/1/configMap/items/0/key","value":"app.yaml"}]'
   ```
   (Removing `items` altogether also works: every key becomes a file.)
