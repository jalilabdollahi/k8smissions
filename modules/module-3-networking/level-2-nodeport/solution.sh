kubectl -n k8smissions get svc -o wide
kubectl -n k8smissions patch service status-page -p '{"spec":{"ports":[{"port":80,"targetPort":5678,"nodePort":30080}]}}' || true
kubectl -n k8smissions get svc --show-labels
kubectl -n k8smissions delete service legacy-status
kubectl -n k8smissions patch service status-page -p '{"spec":{"ports":[{"port":80,"targetPort":5678,"nodePort":30080}]}}'
