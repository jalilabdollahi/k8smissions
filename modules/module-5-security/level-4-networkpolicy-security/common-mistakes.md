## Mistakes on this level

- **Adding another policy.** A new allow-only-the-API policy changes nothing: NetworkPolicies are additive, and the existing one already admits the whole namespace. Only removing or narrowing the permissive one tightens access.
- **Deleting every policy.** With no policy at all, everything is open, and `debug-shell` reaches the database again. Keep the default-deny and the strict rule.
- **Deleting the strict policy or the default-deny.** Without `payments-db-from-api` the database admits nobody except through the loose rule, and the API would be cut off once that is gone.
- **Deleting the `debug-shell` pod.** It removes the auditor's test client, not the exposure; the validator requires all four workloads to keep running.
