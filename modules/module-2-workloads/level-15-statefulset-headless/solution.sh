kubectl -n k8smissions get statefulset db -o jsonpath='{.spec.serviceName}{"\n"}'
kubectl -n k8smissions get svc
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: db-hs
spec:
  clusterIP: None
  selector: {app: db}
  ports:
  - name: sql
    port: 8080
YAML
kubectl -n k8smissions wait --for=condition=Available deployment/db-monitor --timeout=120s
