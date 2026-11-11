kubectl -n k8smissions logs deploy/report-operator --tail=4
kubectl -n k8smissions patch role report-operator --type=json -p '[
 {"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["pods"],"verbs":["list"]}},
 {"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["configmaps"],"verbs":["create"]}},
 {"op":"add","path":"/rules/-","value":{"apiGroups":["audit.acme.io"],"resources":["reports/status"],"verbs":["patch"]}}
]'
sleep 8
kubectl -n k8smissions get reports
