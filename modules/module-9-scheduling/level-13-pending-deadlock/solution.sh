kubectl -n k8smissions get job,pod -o wide
kubectl -n k8smissions describe pod -l app=trainer | grep -B2 -A3 FailedScheduling | head -12
kubectl -n k8smissions logs -l job-name=train-a --tail=2
kubectl -n k8smissions patch job train-b --type=merge -p '{"spec":{"suspend":true}}'
kubectl -n k8smissions wait --for=condition=complete job/train-a --timeout=150s
kubectl -n k8smissions patch job train-b --type=merge -p '{"spec":{"suspend":false}}'
kubectl -n k8smissions wait --for=condition=complete job/train-b --timeout=150s
kubectl -n k8smissions get job
