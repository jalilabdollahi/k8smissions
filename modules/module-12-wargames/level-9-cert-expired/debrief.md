# Mass Cert Expiry

## What Happened
TLS certificates used for cluster communication expired. In a real cluster this manifests as connection refused errors, x509 certificate has expired errors, and kubectl commands failing.

## The Fix (real clusters)
```bash
# Check certificate expiry
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# Restart control plane components
kubectl -n kube-system rollout restart deployment/coredns
```

## Key Lessons
- **Certificates expire** — kubeadm-provisioned clusters rotate certs annually by default
- **Certificate monitoring** — alert when certs are within 30 days of expiry
- **kubeadm certs renew** — can renew individual or all certificates without cluster downtime
- **cert-manager** — automates TLS certificate lifecycle management in-cluster
