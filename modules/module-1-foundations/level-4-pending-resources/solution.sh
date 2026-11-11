kubectl -n k8smissions get pod report-builder
kubectl -n k8smissions describe pod report-builder | tail -6
kubectl -n k8smissions delete pod report-builder --wait=true
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: report-builder
  namespace: k8smissions
  labels:
    app: report-builder
spec:
  containers:
  - name: builder
    image: python:3.12-alpine
    command: ["python", "-m", "http.server", "8080"]
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet: {path: /, port: 8080}
      periodSeconds: 3
    resources:
      requests:
        cpu: 500m
        memory: 128Mi
      limits:
        memory: 256Mi
YAML
kubectl -n k8smissions wait --for=condition=Ready pod/report-builder --timeout=60s
