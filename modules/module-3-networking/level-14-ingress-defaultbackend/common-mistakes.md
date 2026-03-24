# Common Mistakes — 404 Not Found

## Mistake 1: Checking pod logs for 404 source

**Wrong approach:** Tailing pod logs when the request never reaches pods at all

**Correct approach:** Check Ingress controller logs and kubectl describe ingress first

## Mistake 2: Fixing the path, not the service name

**Wrong approach:** Changing path: / to path: /* assuming path matching is wrong

**Correct approach:** Read the exact backend service name and compare with kubectl get svc
