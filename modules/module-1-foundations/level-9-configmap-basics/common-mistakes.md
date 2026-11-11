## Common mistakes

- **Re-editing the ConfigMap.** It is already correct. Changing it back and forth does not touch the running containers.
- **Deleting the ConfigMap or the Deployment to "refresh" things.** Deleting the ConfigMap breaks new pods (`CreateContainerConfigError`); deleting the Deployment fails the objective, and the validator also wants the Deployment to keep reading `pricing-config`.
- **Hard-coding `TAX_RATE: 0.20` into the Deployment.** The pods would answer correctly, but the next change in the ConfigMap would be ignored again.
- **Trusting `kubectl get cm`.** It shows what is stored, not what a process has loaded. Compare with `exec ... env`.
