kubectl -n k8smissions get pod welcome-page
kubectl -n k8smissions logs welcome-page
kubectl -n k8smissions delete pod welcome-page
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: welcome-page
  namespace: k8smissions
  labels:
    app: welcome-page
spec:
  containers:
  - name: web
    image: nginx:1.27-alpine
    ports:
    - containerPort: 80
YAML
kubectl -n k8smissions wait --for=condition=Ready pod/welcome-page --timeout=60s
