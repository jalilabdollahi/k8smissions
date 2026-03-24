# Common Mistakes - Level 3: Can't Find the Service

## Fastest First Checks
```bash
kubectl get svc,endpoints,endpointslices -n k8smissions
kubectl describe service <name> -n k8smissions
kubectl get pods -n k8smissions --show-labels
```

## ❌ Mistake #1: Checking pods but not the traffic path

**What players try:**
Players see Running pods in Can't Find the Service and assume networking must be fine.

**Why it fails:**
Traffic can still fail because selectors, endpoints, ports, DNS, Ingress rules, or policies are wrong even when the pod itself is healthy.

**Correct approach:**
Trace the request path end-to-end with the focus on cross-namespace service discovery. Confirm that each hop points to the next one correctly.

**Key learning:**
Networking issues are usually path-mapping problems, not pod-liveness problems.
## ❌ Mistake #2: Mixing up names, ports, or paths

**What players try:**
Players change several values at once without proving which mapping is broken.

**Why it fails:**
A single mismatch in selector labels, `targetPort`, DNS name, namespace, or Ingress path can break everything while the rest of the YAML is correct.

**Correct approach:**
Compare the consumer and provider fields directly instead of guessing: label-to-selector, port-to-targetPort, path-to-backend, name-to-FQDN.

**Key learning:**
Most service connectivity bugs are mismatches between two objects that both look valid in isolation.
## ❌ Mistake #3: Forgetting namespace and readiness boundaries

**What players try:**
Players use short service names everywhere or test against pods that are not Ready yet.

**Why it fails:**
Cross-namespace DNS needs the right name, and Services only route to Ready endpoints unless a feature explicitly changes that.

**Correct approach:**
Check namespace scope, ready endpoints, and policy rules before assuming a packet should be able to flow.

**Key learning:**
Discovery and reachability are constrained by scope and readiness, not just object existence.
## ❌ Mistake #4: Validating from the wrong place

**What players try:**
Players test the service from a context that bypasses the broken hop.

**Why it fails:**
Curling the pod IP, port-forwarding, or using localhost can hide the exact layer that is still misconfigured.

**Correct approach:**
Validate through the same path the workload is supposed to use. End goal: Use the validator to confirm the repaired state.

**Key learning:**
Your test path should match the production path you are trying to repair.

## What To Prove Before You Move On
- The Service or Ingress now points to Ready backends.
- You verified selectors, ports, paths, or DNS names end-to-end.
- Use the validator to confirm the repaired state.
