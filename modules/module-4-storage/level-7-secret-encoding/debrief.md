# Debrief: right password, wrong bytes

**What was broken.** The Secret `db-credentials` held `Ledg3r-9fQ2x` followed by a newline. Someone had produced the base64 value with `echo Ledg3r-9fQ2x | base64`, and `echo` appends `\n`. The client read the file and compared the raw bytes with what the database expects, so authentication failed.

**The evidence.** `kubectl logs` only said `auth failed for user ledger`; the password looked right when decoded with `base64 -d`, because a trailing newline is invisible in a terminal. `base64 -d | od -c` printed the bytes and ended with `\n`. The Secret's encoded text also ended in `Cg==` (base64 of a newline), a clue when you know the pattern.

**Why Kubernetes behaves this way.** A Secret is a bag of opaque bytes. Kubernetes never trims or interprets them; a volume writes exactly those bytes to the file, and an application that reads the file gets the newline. Many programs strip whitespace on read, this one deliberately does not, which is true of plenty of real clients and tokens.

**The fix.** Rewrite the value with no trailing byte: `kubectl create secret generic --from-literal=...` (or `printf` / `echo -n` before base64). Because the file is a volume, kubelet refreshes it within about a minute, and a restart picks it up immediately.

**In production.** Never craft base64 by hand. Prefer `--from-literal`, `--from-file` or `stringData`, and have a check that compares the length of a credential. Secrets mounted with `subPath` or read as environment variables do not refresh at all without a restart.

**Commands worth remembering**
- `kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d | od -c`
- `kubectl create secret generic <name> --from-literal=key=value`
- `kubectl rollout restart deployment/<name>`
