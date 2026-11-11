kubectl -n k8smissions logs deploy/status-page --previous
kubectl -n k8smissions patch deployment status-page -p '{"spec":{"template":{"spec":{"volumes":[{"name":"cache","emptyDir":{}},{"name":"run","emptyDir":{}}],"containers":[{"name":"nginx","volumeMounts":[{"name":"cache","mountPath":"/var/cache/nginx"},{"name":"run","mountPath":"/var/run"}]}]}}}}'
kubectl -n k8smissions rollout status deploy/status-page --timeout=90s
