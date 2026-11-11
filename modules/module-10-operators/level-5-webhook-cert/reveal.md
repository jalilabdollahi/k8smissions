Two stacked faults:

1. The webhook's `caBundle` holds a stale CA, so the API server cannot verify the server (`x509: certificate signed by unknown authority`). The right CA is in `policy-guard-tls-reissued` under `ca.crt`.
2. Once the CA is right, the certificate in the pod is expired (`certificate has expired or is not yet valid`). The reissued Secret holds a valid certificate and key. The server loads them only at start, so the pod must be replaced.

```bash
CA=$(kubectl -n k8smissions get secret policy-guard-tls-reissued -o jsonpath='{.data.ca\.crt}')
kubectl patch validatingwebhookconfiguration policy-guard --type=json -p "[{\"op\":\"replace\",\"path\":\"/webhooks/0/clientConfig/caBundle\",\"value\":\"$CA\"}]"
kubectl -n k8smissions patch deployment policy-guard --type=json -p '[{"op":"replace","path":"/spec/template/spec/volumes/2/secret/secretName","value":"policy-guard-tls-reissued"}]'
```

Pointing the Deployment at the other Secret restarts the pod. If you edit the Secret's data in place instead, delete the pod yourself. Keep `failurePolicy: Fail`: removing or loosening the webhook admits `nginx:latest`.
