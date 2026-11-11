kubectl -n k8smissions get pdb
kubectl -n k8smissions describe pdb ledger-api-pdb
kubectl -n k8smissions patch pdb ledger-api-pdb --type=merge -p '{"spec":{"minAvailable":1}}'
