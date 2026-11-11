kubectl -n k8smissions get deploy,svc,cm -l site -o custom-columns=KIND:.kind,NAME:.metadata.name,AGE:.metadata.creationTimestamp,OWNER-UID:.metadata.ownerReferences[0].uid
kubectl -n k8smissions get sites.web.acme.io -o custom-columns=NAME:.metadata.name,UID:.metadata.uid
kubectl -n k8smissions apply -f - <<'Y'
apiVersion: v1
kind: ConfigMap
metadata:
  name: site-operator-code
  namespace: k8smissions
data:
  controller.py: |
    from kapi import api, patch, forever, log, NS

    SITES = "/apis/web.acme.io/v1/namespaces/%s/sites" % NS
    DEPLOYMENTS = "/apis/apps/v1/namespaces/%s/deployments" % NS
    SERVICES = "/api/v1/namespaces/%s/services" % NS
    CONFIGMAPS = "/api/v1/namespaces/%s/configmaps" % NS


    def owner(site):
        return [{"apiVersion": "web.acme.io/v1", "kind": "Site", "name": site["metadata"]["name"],
                 "uid": site["metadata"]["uid"], "controller": True}]


    def ensure(base, name, body):
        code, cur = api("GET", "%s/%s" % (base, name))
        if code == 404:
            code, res = api("POST", base, body)
            log("created %s: %s" % (name, code))
        elif code == 200:
            want = body["metadata"]["ownerReferences"]
            have = cur["metadata"].get("ownerReferences") or []
            if [o["uid"] for o in have] != [o["uid"] for o in want]:
                patch("%s/%s" % (base, name), {"metadata": {"ownerReferences": want}})
                log("fixed owner of %s" % name)


    def reconcile():
        code, body = api("GET", SITES)
        if code != 200:
            log("cannot list sites:", code, body.get("message"))
            return
        for site in body["items"]:
            name = site["metadata"]["name"]
            child = "site-" + name
            labels = {"site": name}
            ensure(DEPLOYMENTS, child, {
                "metadata": {"name": child, "labels": labels, "ownerReferences": owner(site)},
                "spec": {"replicas": 1, "selector": {"matchLabels": labels},
                         "template": {"metadata": {"labels": labels}, "spec": {"containers": [
                             {"name": "web", "image": "busybox:1.36", "command": ["sleep", "86400"]}]}}}})
            ensure(SERVICES, child, {
                "metadata": {"name": child, "labels": labels, "ownerReferences": owner(site)},
                "spec": {"selector": labels, "ports": [{"port": 80, "targetPort": 8080}]}})
            ensure(CONFIGMAPS, child, {
                "metadata": {"name": child, "labels": labels, "ownerReferences": owner(site)},
                "data": {"host": site["spec"]["host"]}})


    forever(reconcile)
Y
kubectl -n k8smissions rollout restart deploy/site-operator
kubectl -n k8smissions rollout status deploy/site-operator --timeout=90s
kubectl -n k8smissions delete svc site-legacy
