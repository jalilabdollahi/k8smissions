# Common Mistakes — Connection Refused

## Mistake 1: Checking only Service port, not targetPort

**Wrong approach:** kubectl get svc shows port 80 and concluding everything is correct

**Correct approach:** Always check both port (incoming to Service) AND targetPort (forwarded to pod)

## Mistake 2: Assuming readiness probe failure is the cause

**Wrong approach:** Editing the readiness probe when the real issue is targetPort mismatch

**Correct approach:** Check endpoints first; if endpoints are empty, selector or targetPort is the problem
