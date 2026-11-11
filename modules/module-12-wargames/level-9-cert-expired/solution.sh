#!/bin/bash
NS=k8smissions
d=$(mktemp -d); cd "$d" || exit 1
kubectl -n $NS get secret internal-ca -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl -n $NS get secret internal-ca -o jsonpath='{.data.ca\.key}' | base64 -d > ca.key

issue() {  # issue <name> <subject CN> <extfile contents>
  openssl ecparam -name prime256v1 -genkey -noout -out "$1.key"
  openssl req -new -key "$1.key" -subj "/CN=$2" -out "$1.csr"
  printf "$3" > "$1.ext"
  openssl x509 -req -in "$1.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -days 90 -extfile "$1.ext" -out "$1.crt"
}
# server: keep the names the old certificate had
issue ledger ledger.k8smissions.svc 'subjectAltName=DNS:ledger,DNS:ledger.k8smissions,DNS:ledger.k8smissions.svc,DNS:ledger.k8smissions.svc.cluster.local\nextendedKeyUsage=serverAuth\n'
issue gateway gateway-client 'extendedKeyUsage=clientAuth\n'

kubectl -n $NS create secret tls ledger-tls --cert=ledger.crt --key=ledger.key --dry-run=client -o yaml | kubectl apply -f -
kubectl -n $NS create secret tls gateway-client-tls --cert=gateway.crt --key=gateway.key --dry-run=client -o yaml | kubectl apply -f -
# ledger mounts its files with subPath: a Secret update never reaches running pods
kubectl -n $NS rollout restart deploy/ledger deploy/gateway
kubectl -n $NS rollout status deploy/ledger --timeout=120s
kubectl -n $NS rollout status deploy/gateway --timeout=120s
