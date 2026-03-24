# CHAOS FINALE: The Perfect Storm

## Situation
Production emergency! Multiple simultaneous failures. All issues from Module 5 combined into one scenario: 1. RBAC: app-sa missing RoleBinding 2. SecurityContext: running as root 3. ResourceQuota: limit exceeded 4. NetworkPolicy: database unreachable 5. Node Affinity: wrong label selector 6. Taints: missing toleration 7. PDB: blocking drain 8. Pod Security: restricted violation 9. PriorityClass: critical pod stuck behind dev pods

## Successful Fix
Systematically fix all 9 issues (checklist provided in hints)

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for CHAOS FINALE: The Perfect Storm.

## Concepts
All Module 5 concepts combined, incident response workflow, priority triaging in production
