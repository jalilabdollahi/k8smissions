kubectl -n k8smissions logs deploy/invoice-mailer --tail=3
kubectl -n k8smissions get deploy invoice-mailer -o jsonpath='{.spec.template.spec.containers[0].env}{"\n"}'
kubectl -n k8smissions patch deployment invoice-mailer --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env","value":[{"name":"SMTP_HOST","value":"smtp-relay"},{"name":"SMTP_PORT","value":"2525"},{"name":"SMTP_URL","value":"http://$(SMTP_HOST):$(SMTP_PORT)/send"}]}]'
kubectl -n k8smissions rollout status deployment/invoice-mailer --timeout=90s
sleep 8
