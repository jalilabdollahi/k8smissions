kubectl -n k8smissions get cronjob close-report
kubectl -n k8smissions describe cronjob close-report | head -20
kubectl -n k8smissions patch cronjob close-report -p '{"spec":{"suspend":false,"schedule":"* * * * *"}}'
kubectl -n k8smissions get cronjob close-report
for i in $(seq 1 24); do
  kubectl -n k8smissions get jobs 2>/dev/null | grep -q close-report && break
  sleep 5
done
kubectl -n k8smissions get jobs
