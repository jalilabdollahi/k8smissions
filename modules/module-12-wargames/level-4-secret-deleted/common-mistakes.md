# Common Mistakes — Credential Void

## ❌ Restarting the pod before recreating the secret
The pod will still fail — the secret must exist first.

## ❌ Wrong key names
The deployment references keys 'username' and 'password' — the secret must use exactly those key names.
