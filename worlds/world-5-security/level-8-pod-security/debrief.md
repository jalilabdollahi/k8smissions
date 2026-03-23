# Restricted Policy Violation

## Situation
Namespace enforces Pod Security Standard "restricted". Pod runs as root with privileged: true. Rejected.

## Successful Fix
securityContext: runAsNonRoot: true, runAsUser: 1000, allowPrivilegeEscalation: false, seccompProfile: RuntimeDefault

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Restricted Policy Violation.

## Concepts
Pod Security Standards (PSS): privileged/baseline/restricted, Pod Security Admission (PSA), namespace labels
