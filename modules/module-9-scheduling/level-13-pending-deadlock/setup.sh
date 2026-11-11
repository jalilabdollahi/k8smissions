#!/bin/bash
# Room for exactly 4 trainer pods. Both Jobs start with parallelism 2 (4 pods run), then each is raised to 3.
. ../_fixtures/lib.sh
a=$(worker_n 1); b=$(worker_n 2)
fa=$(free_cpu_m "$a"); fb=$(free_cpu_m "$b")
req=$(( (fa + fb) / 2 * 40 / 100 ))
[ "$req" -ge 20 ] || { echo "not enough free cpu ($fa, $fb) for the scenario"; exit 1; }

kubectl -n "$NS" apply -f - <<YAML
apiVersion: v1
kind: ServiceAccount
metadata: {name: trainer, namespace: k8smissions}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: peer-reader, namespace: k8smissions}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: trainer-peer-reader, namespace: k8smissions}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: peer-reader}
subjects:
- {kind: ServiceAccount, name: trainer, namespace: k8smissions}
---
apiVersion: v1
kind: ConfigMap
metadata: {name: barrier, namespace: k8smissions}
data:
  barrier.py: |
    import json, os, ssl, time, urllib.request
    ns, job, need = os.environ["NS"], os.environ["JOB"], int(os.environ["PEERS"])
    sa = "/var/run/secrets/kubernetes.io/serviceaccount/"
    token = open(sa + "token").read()
    ctx = ssl.create_default_context(cafile=sa + "ca.crt")
    url = f"https://kubernetes.default.svc/api/v1/namespaces/{ns}/pods?labelSelector=job-name%3D{job}"
    last = -1
    while True:
        req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
        items = json.load(urllib.request.urlopen(req, context=ctx))["items"]
        n = sum(1 for p in items if p["status"].get("phase") in ("Running", "Succeeded")
                and not p["metadata"].get("deletionTimestamp"))
        if n != last:
            print(f"{job}: {n} of {need} peers running", flush=True)
            last = n
        if n >= need:
            print(f"{job}: barrier passed with {n} of {need} peers", flush=True)
            time.sleep(4)
            print(f"{job}: shard trained", flush=True)
            break
        time.sleep(2)
YAML

for j in a b; do
kubectl -n "$NS" apply -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: train-$j
  namespace: k8smissions
spec:
  completions: 3
  parallelism: 2
  backoffLimit: 4
  template:
    metadata:
      labels: {app: trainer, run: $j}
    spec:
      serviceAccountName: trainer
      restartPolicy: Never
      terminationGracePeriodSeconds: 1
      containers:
      - name: worker
        image: python:3.12-alpine
        command: ["python", "-u", "/app/barrier.py"]
        env:
        - {name: NS, value: k8smissions}
        - {name: JOB, value: train-$j}
        - {name: PEERS, value: "3"}
        resources:
          requests: {cpu: ${req}m, memory: 32Mi}
        volumeMounts:
        - {name: barrier, mountPath: /app}
      volumes:
      - name: barrier
        configMap: {name: barrier}
YAML
done
wait_pods_ready app=trainer 4 150 || exit 1
kubectl -n "$NS" patch job train-a --type=merge -p '{"spec":{"parallelism":3}}'
kubectl -n "$NS" patch job train-b --type=merge -p '{"spec":{"parallelism":3}}'
sleep 5
