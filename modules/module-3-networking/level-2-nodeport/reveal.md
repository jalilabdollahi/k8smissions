Port 30080 is already allocated to the decommissioned Service `legacy-status`, so the API server refuses to give it to `status-page`.

1. `kubectl -n k8smissions get svc -o wide` shows `legacy-status` on `80:30080/TCP`; `describe` shows it has no endpoints.
2. `kubectl -n k8smissions delete service legacy-status` releases the port.
3. `kubectl -n k8smissions patch service status-page -p '{"spec":{"ports":[{"port":80,"targetPort":5678,"nodePort":30080}]}}'` claims it.
