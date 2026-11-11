## Mistakes on this level

- **Looking at pods.** There are none, so `describe pod` finds nothing. The failure lives on the ReplicaSet; read its events.
- **Raising the quota.** It would unblock this team and defeat the guardrail; the validator requires `limits.cpu: 2` and `limits.memory: 2Gi` to stay.
- **Generous limits.** Setting `limits.cpu=1` gives `exceeded quota`: two pods start, the third is refused. Divide the quota by 3 (and by any other workload in the namespace).
- **Setting only the CPU limit.** The error names both `limits.cpu` and `limits.memory`; both must be declared.
