NS=k8smissions
kubectl -n gitops-git port-forward svc/gitserver 18112:8080 >/dev/null 2>&1 &
trap 'kill %1' EXIT
sleep 2
git clone -q http://localhost:18112/cgi-bin/git/payments.git payments
cd payments
kubectl kustomize overlays/prod | grep -E 'replicas|image:'
kubectl -n $NS get deploy payments -o jsonpath='{.metadata.name} {.spec.template.spec.containers[0].image}{"\n"}'
cat > overlays/prod/kustomization.yaml <<'YAML'
resources:
- ../../base
labels:
- pairs: {env: prod}
patches:
- target:
    kind: Deployment
    name: payments
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 4
images:
- name: hashicorp/http-echo
  newTag: "1.0"
YAML
kubectl kustomize overlays/prod | grep -E 'replicas|image:'
git -c user.name=oncall -c user.email=oncall@example.com commit -qam "prod overlay: patch target and image entry match what the base declares"
git push -q origin main
kubectl apply -n $NS -k overlays/prod
kubectl -n $NS rollout status deploy/payments --timeout=120s
