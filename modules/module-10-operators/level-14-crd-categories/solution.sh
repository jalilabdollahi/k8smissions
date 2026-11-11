kubectl api-resources --categories=all | head -20
kubectl get crd invoicebatches.billing.acme.io -o jsonpath='{.spec.names}{"\n"}'
kubectl patch crd invoicebatches.billing.acme.io --type=json -p '[
  {"op":"add","path":"/spec/names/categories","value":["all"]},
  {"op":"add","path":"/spec/names/shortNames","value":["ib"]},
  {"op":"add","path":"/spec/versions/0/additionalPrinterColumns","value":[
    {"name":"State","type":"string","jsonPath":".status.state"},
    {"name":"Progress","type":"string","jsonPath":".status.progress"}]}
]'
for i in $(seq 1 15); do
  kubectl -n k8smissions get ib 2>/dev/null | grep -q STATE && break
  sleep 2
done
kubectl -n k8smissions get ib
kubectl -n k8smissions get all
