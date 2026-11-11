#!/bin/bash
. ../_fixtures/lib.sh
lab_ns

# "labeler-system" plays the part of kube-system; "shop" is the application namespace.
for n in labeler-system shop; do
  kubectl create namespace "$n" >/dev/null
  kubectl label namespace "$n" k8smissions/lab=true k8smissions/managed=true >/dev/null
done

NS=labeler-system install_webhook_server
tls_secret pod-labeler-tls good-labeler labeler-system

kubectl apply -f - >/dev/null <<'Y'
apiVersion: v1
kind: ConfigMap
metadata:
  name: pod-labeler-handler
  namespace: labeler-system
data:
  handler.py: |
    # Mutating handler: every admitted pod gets the label labeler/injected=true.
    def mutate(req):
        labels = req["object"]["metadata"].get("labels")
        if labels is None:
            return True, "", [{"op": "add", "path": "/metadata/labels", "value": {"labeler/injected": "true"}}]
        return True, "", [{"op": "add", "path": "/metadata/labels/labeler~1injected", "value": "true"}]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-labeler
  namespace: labeler-system
spec:
  replicas: 1
  selector:
    matchLabels: {app: pod-labeler}
  template:
    metadata:
      labels: {app: pod-labeler}
    spec:
      containers:
      - name: server
        image: python:3.12-alpine
        command: ["python", "-u", "/app/server.py"]
        readinessProbe:
          tcpSocket: {port: 8443}
        volumeMounts:
        - {name: app, mountPath: /app}
        - {name: handler, mountPath: /handler}
        - {name: tls, mountPath: /tls}
      volumes:
      - {name: app, configMap: {name: webhook-server}}
      - {name: handler, configMap: {name: pod-labeler-handler}}
      - {name: tls, secret: {secretName: pod-labeler-tls}}
---
apiVersion: v1
kind: Service
metadata:
  name: pod-labeler
  namespace: labeler-system
spec:
  selector: {app: pod-labeler}
  ports:
  - {port: 443, targetPort: 8443}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storefront
  namespace: shop
spec:
  replicas: 2
  selector:
    matchLabels: {app: storefront}
  template:
    metadata:
      labels: {app: storefront}
    spec:
      containers:
      - name: web
        image: busybox:1.36
        command: ["sleep", "86400"]
Y
kubectl -n labeler-system rollout status deploy/pod-labeler --timeout=120s >/dev/null
kubectl -n shop rollout status deploy/storefront --timeout=120s >/dev/null

# Last night's maintenance: the server was scaled down, the webhook registered, then everything restarted.
kubectl -n labeler-system scale deploy/pod-labeler --replicas=0 >/dev/null
for i in $(seq 1 30); do
  [ -z "$(kubectl -n labeler-system get pods -l app=pod-labeler -o name)" ] && break
  sleep 1
done

apply_managed <<Y
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: pod-labeler
webhooks:
- name: labeler.platform.acme.io
  clientConfig:
    service: {name: pod-labeler, namespace: labeler-system, path: /mutate, port: 443}
    caBundle: $(cabundle ca-a)
  rules:
  - {apiGroups: [""], apiVersions: [v1], operations: [CREATE], resources: [pods]}
  namespaceSelector:
    matchLabels: {k8smissions/lab: "true"}
  failurePolicy: Fail
  sideEffects: None
  admissionReviewVersions: [v1]
  timeoutSeconds: 5
Y

kubectl -n labeler-system scale deploy/pod-labeler --replicas=1 >/dev/null
kubectl -n shop rollout restart deploy/storefront >/dev/null
