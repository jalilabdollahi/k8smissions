kubectl -n k8smissions get pods -l app=workload-operator
kubectl -n k8smissions logs deploy/workload-operator --previous --tail=8
kubectl -n k8smissions get cm release-manifests -o jsonpath='{.data.crds\.yaml}' | kubectl apply -f -
kubectl wait --for=condition=Established crd/workloads.platform.acme.io --timeout=60s
kubectl -n k8smissions get cm release-manifests -o jsonpath='{.data.workloads\.yaml}' | kubectl apply -f -
kubectl -n k8smissions apply -f - <<'Y'
apiVersion: v1
kind: ConfigMap
metadata:
  name: workload-operator-code
  namespace: k8smissions
data:
  controller.py: |
    import time
    from kapi import api, patch, log, NS

    LIST = "/apis/platform.acme.io/v1/namespaces/%s/workloads" % NS


    def reconcile():
        code, body = api("GET", LIST)
        if code != 200:
            log("cannot list workloads:", code, body.get("message"))
            return
        for w in body.get("items") or []:
            name = w["metadata"]["name"]
            options = (w.get("spec") or {}).get("options") or {}
            retries = options.get("retries", 1)
            patch("%s/%s/status" % (LIST, name), {"status": {"phase": "Running", "retries": retries}})
            log("reconciled %s (retries=%d)" % (name, retries))


    log("workload-operator starting")
    while True:
        reconcile()
        time.sleep(2)
Y
kubectl -n k8smissions rollout restart deploy/workload-operator
kubectl -n k8smissions rollout status deploy/workload-operator --timeout=90s
