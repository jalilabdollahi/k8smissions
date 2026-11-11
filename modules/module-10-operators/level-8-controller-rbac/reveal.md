The operator needs three more permissions than its Role grants, each of which only shows after the previous one is fixed (it handles a Report one step at a time):

1. count pods: `list` on `pods` (core group `""`)
2. write the summary: `create` on `configmaps`
3. update status: `patch` on `reports/status` in group `audit.acme.io` (a subresource is a separate resource for RBAC; `reports` does not cover it)

```bash
kubectl -n k8smissions patch role report-operator --type=json -p '[
 {"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["pods"],"verbs":["list"]}},
 {"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["configmaps"],"verbs":["create"]}},
 {"op":"add","path":"/rules/-","value":{"apiGroups":["audit.acme.io"],"resources":["reports/status"],"verbs":["patch"]}}
]'
```

Do not bind `cluster-admin` and do not use `*`: it also fixes the 403s but gives a reporting tool the keys to the whole namespace and the cluster.
