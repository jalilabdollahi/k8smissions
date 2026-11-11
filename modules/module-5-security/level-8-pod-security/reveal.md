**Fix**

1. `kubectl -n pay-restricted describe rs`: `violates PodSecurity "restricted:latest"` listing `allowPrivilegeEscalation`, `unrestricted capabilities`, `runAsNonRoot` and `seccompProfile`, for both the init container `prepare` and the app container `web`.
2. At pod level: `runAsNonRoot: true`, `runAsUser: 101`, `seccompProfile: {type: RuntimeDefault}`.
3. In **both** containers: `allowPrivilegeEscalation: false` and `capabilities: {drop: ["ALL"]}`.
4. One patch does it (see solution); the namespace label stays `enforce=restricted`.
