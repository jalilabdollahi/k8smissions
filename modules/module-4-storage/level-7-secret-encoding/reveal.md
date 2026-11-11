# Reveal

The Secret's `password` was generated with `echo`, which appends a newline, so the stored value is `Ledg3r-9fQ2x\n` (13 bytes). The app compares the exact bytes.

1. Show the stray byte: `kubectl get secret db-credentials -n k8smissions -o jsonpath='{.data.password}' | base64 -d | od -c` ends with `\n`.
2. Rewrite the value without it (`--from-literal` never adds a newline):

   ```bash
   kubectl create secret generic db-credentials -n k8smissions \
     --from-literal=username=ledger --from-literal=password=Ledg3r-9fQ2x \
     --dry-run=client -o yaml | kubectl apply -f -
   ```
3. Restart the pod so it re-reads the file immediately (`kubectl rollout restart deployment/db-client -n k8smissions`); a mounted Secret would otherwise refresh on its own within about a minute.
