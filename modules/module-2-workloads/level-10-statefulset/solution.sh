kubectl -n k8smissions get svc,deploy,pods -l app=ledger-db
kubectl -n k8smissions delete deployment ledger-db
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ledger-db
spec:
  serviceName: ledger-db
  replicas: 3
  selector:
    matchLabels: {app: ledger-db}
  template:
    metadata:
      labels: {app: ledger-db}
    spec:
      containers:
      - name: member
        image: busybox:1.36
        command:
        - sh
        - -c
        - mkdir -p /www && echo "$HOSTNAME" > /www/index.html && exec httpd -f -p 8080 -h /www
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet: {path: /, port: 8080}
          periodSeconds: 2
YAML
kubectl -n k8smissions rollout status statefulset/ledger-db --timeout=120s
