**What was broken.** Mutual TLS between `gateway` and `ledger` needs two valid certificates signed by the internal CA, and both had expired in 2024. On top of that `ledger` mounted its certificate files with `subPath`, so even a corrected Secret would not reach its running pods.

**The evidence.** The gateway's 502 body and log name the problem: `certificate verify failed: certificate has expired`. `openssl x509 -noout -dates` on the Secret contents shows `notAfter` in the past. After the server certificate is fixed the message changes side: `ledger` logs a handshake failure and `gateway` receives a TLS alert, which is the client certificate. And `get deploy ledger -o yaml` shows `subPath` on the TLS mounts.

**Why Kubernetes behaved this way.** Kubernetes does not manage these certificates; they are plain Secrets that the applications load. A TLS peer verifies the other side's chain, name and validity period, so every certificate in the chain of trust has its own clock. A Secret mounted as a directory is refreshed by the kubelet after a delay of up to a minute or two, while a `subPath` mount is a one-time bind of a single file and never changes. Because the app here reloads files per connection, a restart is what makes the `subPath` pods see the new files.

**The fix.** Issue server and client certificates from `internal-ca`, with the server's names in the SAN list and `clientAuth` for the client, update both Secrets, and restart what mounts them by `subPath`. A self-signed certificate would not chain to the CA.

**In production.** Use cert-manager with short-lived certificates and `renewBefore`, alert on `notAfter` well before expiry, mount Secrets as directories, and reload on change.

**Commands to remember.** `openssl x509 -noout -dates -subject -issuer`, `openssl s_client -connect host:port -CAfile ca.crt`, `kubectl create secret tls <name> --cert --key --dry-run=client -o yaml | kubectl apply -f -`.
