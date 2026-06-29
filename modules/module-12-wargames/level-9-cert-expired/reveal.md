## What went wrong

Kubernetes cluster certificates (API server TLS, kubelet client cert, etcd peer certs) expire after 1 year by default when created with kubeadm. After expiry, all TLS handshakes fail — kubectl returns x509 errors, components can't communicate with the API server, and the cluster is effectively down.

## Fix

```yaml
metadata:
  annotations:
    cert-status: valid
    expiry: '2027-01-01'
stringData:
  status: valid
```

Real cluster cert renewal:
```bash
kubeadm certs check-expiration
kubeadm certs renew all
# Restart static pods (they use cert files directly):
kubectl -n kube-system rollout restart deployment/coredns
# kube-apiserver, scheduler, controller-manager restart automatically as static pods
```

## Why this matters

Certificate expiry is a silent time bomb — everything works until midnight on expiry day, then nothing works. Prevention:
1. **Monitoring**: alert when any cert has `<30 days` remaining (`kubeadm certs check-expiration` in a CronJob)
2. **Automated renewal**: cert-manager can manage cluster certificates and auto-renew; Kubernetes 1.15+ auto-rotates kubelet client certs if `RotateKubeletClientCertificate` is enabled
3. **Annual calendar reminder**: set a reminder 30 days before each cert's anniversary
4. **kubeadm upgrade**: running `kubeadm upgrade apply` also renews certificates as a side effect