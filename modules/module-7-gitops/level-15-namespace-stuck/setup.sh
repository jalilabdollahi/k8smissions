#!/bin/bash
# a tenant namespace managed by Argo, a neighbour that must survive, and an aggregated API whose backend is gone
kubectl create namespace keep-me
kubectl label namespace keep-me k8smissions/managed=true
kubectl -n keep-me apply -f ../_fixtures/probe.yaml
kubectl -n keep-me wait --for=condition=Ready pod/probe --timeout=120s >/dev/null
uid=$(kubectl -n keep-me get pod probe -o jsonpath='{.metadata.uid}')
kubectl annotate namespace keep-me k8smissions/probe-uid="$uid" >/dev/null

../_fixtures/gitserver/seed.sh sandbox repo "payments-sandbox: namespace, quota and sandbox-api"
../_fixtures/argo-app.sh app.yaml
until [ "$(kubectl -n argocd get app payments-sandbox -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null)" = Synced/Healthy ]; do sleep 3; done

kubectl -n "$NS" apply -f - >/dev/null <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: reports-api
  labels: {k8smissions/managed: "true"}
spec:
  selector: {app: reports-api}
  ports:
  - port: 443
    targetPort: 8443
YAML
kubectl apply -f - >/dev/null <<'YAML'
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.reports.example.io
  labels: {k8smissions/managed: "true"}
spec:
  group: reports.example.io
  version: v1beta1
  groupPriorityMinimum: 1000
  versionPriority: 15
  insecureSkipTLSVerify: true
  service:
    name: reports-api
    namespace: k8smissions
    port: 443
YAML
until [ "$(kubectl get apiservice v1beta1.reports.example.io -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" = False ]; do sleep 2; done

# the tenant is offboarded: the Application is deleted, cascading to the namespace it owns
kubectl -n argocd delete application payments-sandbox --wait=false >/dev/null
until [ "$(kubectl get ns payments-sandbox -o jsonpath='{.status.phase}' 2>/dev/null)" = Terminating ]; do sleep 2; done
sleep 10
