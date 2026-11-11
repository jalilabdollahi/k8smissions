kubectl -n k8smissions logs deploy/backup-operator --tail=3
kubectl patch crd backups.backup.acme.io --type=json -p '[{"op":"add","path":"/spec/versions/0/subresources","value":{"status":{}}}]'
# the reporter wrote status through the main endpoint, which now ignores it
kubectl -n k8smissions get cm sla-reporter-code -o jsonpath='{.data.sla\.py}' > sla.py
sed -i.bak 's|patch(BASE + "/" + b\["metadata"\]\["name"\],|patch(BASE + "/" + b["metadata"]["name"] + "/status",|' sla.py
grep -n '/status' sla.py
kubectl -n k8smissions create configmap sla-reporter-code --from-file=sla.py=sla.py --dry-run=client -o yaml | kubectl apply -f -
sleep 6
kubectl -n k8smissions get backups
