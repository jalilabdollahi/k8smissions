kubectl -n pay-restricted describe rs | grep -A4 -i violates
kubectl -n pay-restricted patch deployment report-ui --type=strategic -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":101,"seccompProfile":{"type":"RuntimeDefault"}},"initContainers":[{"name":"prepare","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}],"containers":[{"name":"web","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
kubectl -n pay-restricted rollout status deploy/report-ui --timeout=100s
