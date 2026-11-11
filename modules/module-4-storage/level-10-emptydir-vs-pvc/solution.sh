#!/bin/bash
# Give the uploads volume a claim and point the pod's volume at it; scratch stays an emptyDir.
kubectl get deployment data-app -n k8smissions -o jsonpath='{.spec.template.spec.volumes}'; echo
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: customer-uploads
  namespace: k8smissions
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
YAML
kubectl patch deployment data-app -n k8smissions --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/volumes/1","value":{"name":"uploads","persistentVolumeClaim":{"claimName":"customer-uploads"}}}]'
kubectl rollout status deployment/data-app -n k8smissions --timeout=120s
