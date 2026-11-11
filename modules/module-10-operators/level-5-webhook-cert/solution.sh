kubectl -n k8smissions get secret
CA=$(kubectl -n k8smissions get secret policy-guard-tls-reissued -o jsonpath='{.data.ca\.crt}')
kubectl patch validatingwebhookconfiguration policy-guard --type=json -p "[{\"op\":\"replace\",\"path\":\"/webhooks/0/clientConfig/caBundle\",\"value\":\"$CA\"}]"
kubectl -n k8smissions patch deployment policy-guard --type=json -p '[{"op":"replace","path":"/spec/template/spec/volumes/2/secret/secretName","value":"policy-guard-tls-reissued"}]'
kubectl -n k8smissions rollout status deployment/policy-guard --timeout=90s
