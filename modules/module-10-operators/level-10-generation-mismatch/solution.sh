kubectl -n k8smissions logs deploy/inventory-operator --tail=6
kubectl -n k8smissions apply -f - <<'Y'
apiVersion: v1
kind: ConfigMap
metadata:
  name: inventory-operator-code
  namespace: k8smissions
data:
  controller.py: |
    import time
    from kapi import api, patch, forever, log, NS

    BASE = "/apis/stock.acme.io/v1/namespaces/%s/inventories" % NS
    CMS = "/api/v1/namespaces/%s/configmaps" % NS


    def ensure_child(name, spec):
        want = {"sku": spec["sku"], "reorderLevel": str(spec["reorderLevel"])}
        path = "%s/inventory-%s" % (CMS, name)
        code, cm = api("GET", path)
        if code == 404:
            api("POST", CMS, {"metadata": {"name": "inventory-" + name}, "data": want})
            log("created child ConfigMap for", name)
        elif code == 200 and cm.get("data") != want:
            patch(path, {"data": want})
            log("updated child ConfigMap for", name)


    def reconcile():
        code, body = api("GET", BASE)
        if code != 200:
            log("cannot list inventories:", code, body.get("message"))
            return
        for item in body["items"]:
            name = item["metadata"]["name"]
            ensure_child(name, item["spec"])
            status = item.get("status") or {}
            gen = item["metadata"]["generation"]
            if status.get("observedGeneration") != gen or status.get("phase") != "Synced":
                patch("%s/%s/status" % (BASE, name), {"status": {
                    "phase": "Synced",
                    "observedGeneration": gen,
                    "lastSync": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                }})
                log("reconciled %s generation %s" % (name, gen))


    forever(reconcile)
Y
kubectl -n k8smissions rollout restart deploy/inventory-operator
kubectl -n k8smissions rollout status deploy/inventory-operator --timeout=90s
