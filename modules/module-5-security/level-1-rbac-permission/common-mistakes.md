# Common Mistakes - Level 1: Forbidden!

## Fastest First Checks
```bash
kubectl auth can-i <verb> <resource> -n k8smissions --as=system:serviceaccount:k8smissions:<sa>
kubectl describe role,rolebinding,serviceaccount -n k8smissions
kubectl describe pod <pod> -n k8smissions
```

## ❌ Mistake #1: Using a privileged shortcut instead of the minimal fix

**What players try:**
Players solve Forbidden! by granting broad permissions or relaxing security constraints too far.

**Why it fails:**
That may make the workload pass, but it teaches the wrong habit and hides the real boundary that Kubernetes is enforcing.

**Correct approach:**
Grant only the permission, binding, or security setting the workload actually needs, and no more.

**Key learning:**
A correct security fix is precise. Over-permission is not a win.
## ❌ Mistake #2: Confusing scope: pod, namespace, or cluster

**What players try:**
Players create the right-looking object in the wrong scope or bind the wrong subject.

**Why it fails:**
RBAC and admission controls are highly scope-sensitive. A Role is not a ClusterRole, and a ServiceAccount in one namespace is a different identity from the same name elsewhere.

**Correct approach:**
Verify subject, verb, resource, and scope explicitly. In this level the main focus is RBAC scope and bindings.

**Key learning:**
Security failures are often scope mistakes, not syntax mistakes.
## ❌ Mistake #3: Ignoring how the denial is enforced

**What players try:**
Players treat all 'forbidden' behavior as the same kind of problem.

**Why it fails:**
Some denials come from RBAC, some from Pod Security Admission, and some from runtime UID, capability, or filesystem settings.

**Correct approach:**
Read the event or error message closely so you fix the right enforcement layer.

**Key learning:**
You fix RBAC, admission, and runtime hardening in different places.
## ❌ Mistake #4: Not proving the exact permission or policy change

**What players try:**
Players apply a change and stop when the workload starts once.

**Why it fails:**
Without an explicit check, you may not know whether you fixed the intended rule or just changed something broad enough to hide it.

**Correct approach:**
Use targeted verification such as `kubectl auth can-i` or admission events, then confirm the workload target: Use the validator to confirm the repaired state.

**Key learning:**
Security changes should be testable and explainable, not just 'it works now'.

## What To Prove Before You Move On
- The workload has only the permission level it actually needs.
- You verified whether the denial came from RBAC, admission, or runtime user settings.
- Use the validator to confirm the repaired state.
