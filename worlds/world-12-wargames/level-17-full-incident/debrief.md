# P0 Incident

## What Happened
Five independent failures hit simultaneously — typical of a bad deployment pipeline run that made multiple changes at once. Each failure blocked a different path to recovery.

## The Fix (in dependency order)
1. **Create the Secret**: `kubectl create secret generic p0-secret --from-literal=password=productionpassword -n k8smissions`
2. **Create missing ServiceAccount**: `kubectl create serviceaccount p0-sa -n k8smissions`
3. **Fix Deployment**: Remove nodeSelector, set replicas to 2
4. **Fix NetworkPolicy**: Add egress allow for UDP/TCP port 53 (DNS)
5. **Fix PVC**: Change storage request from 999Ti to 1Gi

## Key Lessons
- **Triage methodology**: start with the dependency that blocks the most other fixes
- **Secret and SA first** — pods can't start without them
- **NetworkPolicy DNS egress** — forgetting UDP 53 is an extremely common mistake
- **All failures have blast radius** — in a real P0, coordinate with the team and fix the highest-impact issue first

## Incident Checklist
```bash
kubectl get all,pvc,secret,networkpolicy,pdb -n k8smissions
```
