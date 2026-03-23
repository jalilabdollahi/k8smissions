# False Security

## Situation
A Secret contains a password. The team thinks it's "encrypted" because it's base64. You must demonstrate that base64 is trivially reversible and fix the real security gap by enforcing RBAC on the secret.

## Successful Fix
echo "dmFsdWU=" | base64 -d  (show it decodes instantly) Apply Role restricting secret access to specific SA only

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for False Security.

## Concepts
base64 vs encryption, Secrets at rest, RBAC for secrets, Vault, Sealed Secrets, External Secrets Operator
