**Renewing only the server certificate.** The error message changes side but the incident goes on: mutual TLS means the client certificate has its own expiry, and `ledger` rejects the expired one. Check the dates of every certificate in the path.

**Updating the Secret and waiting.** `ledger` mounts the files by `subPath`, which Kubernetes never refreshes in running containers, so the Secret is correct and the pods still hold the old expired file. Restart the Deployment (or mount the directory without `subPath`).

**Generating a self-signed certificate, or turning verification off.** A self-signed server certificate does not chain to `internal-ca`, so `gateway` rejects it, and disabling verification would leave the connection unauthenticated. Sign new certificates with the CA key in `internal-ca`, and give the server certificate the names the old one had.
