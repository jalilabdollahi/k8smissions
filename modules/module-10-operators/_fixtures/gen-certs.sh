#!/bin/bash
# Regenerates certs/. NOT run by any level: the PEM files are committed so results never change.
# Needs OpenSSL 3.4+ (x509 -not_before/-not_after). All dates are fixed far in the past/future.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf certs && mkdir -p certs/{ca-a,ca-b,good,expired,nosan,good-labeler}
FAR_PAST=20200101000000Z; PAST_END=20210101000000Z; CA_START=20200101000000Z; CA_END=21200101000000Z

ca() {  # ca <dir> <cn>
  openssl ecparam -name prime256v1 -genkey -noout -out "certs/$1/ca.key"
  openssl req -new -key "certs/$1/ca.key" -subj "/CN=$2" -out "certs/$1/ca.csr"
  openssl x509 -req -in "certs/$1/ca.csr" -signkey "certs/$1/ca.key" -not_before $CA_START -not_after $CA_END \
    -extfile <(printf 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\n') \
    -out "certs/$1/ca.crt"
  rm "certs/$1/ca.csr"
}
leaf() {  # leaf <dir> <cn> <san-or-empty> <not_before> <not_after>
  openssl ecparam -name prime256v1 -genkey -noout -out "certs/$1/tls.key"
  openssl req -new -key "certs/$1/tls.key" -subj "/CN=$2" -out "certs/$1/tls.csr"
  ext='basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth\n'
  [ -n "$3" ] && ext="${ext}subjectAltName=$3\n"
  openssl x509 -req -in "certs/$1/tls.csr" -CA certs/ca-a/ca.crt -CAkey certs/ca-a/ca.key -CAcreateserial \
    -not_before "$4" -not_after "$5" -extfile <(printf "$ext") -out "certs/$1/tls.crt"
  rm "certs/$1/tls.csr"
}
ca ca-a "k8smissions-fixture-ca-a"
ca ca-b "k8smissions-fixture-ca-b"
leaf good "webhook.k8smissions.svc" "DNS:*.k8smissions.svc,DNS:*.k8smissions.svc.cluster.local" $CA_START $CA_END
leaf expired "webhook.k8smissions.svc" "DNS:*.k8smissions.svc,DNS:*.k8smissions.svc.cluster.local" $FAR_PAST $PAST_END
leaf nosan "webhook.k8smissions.svc" "" $CA_START $CA_END
leaf good-labeler "webhook.labeler-system.svc" "DNS:*.labeler-system.svc,DNS:*.labeler-system.svc.cluster.local" $CA_START $CA_END
rm -f certs/ca-a/ca.key.bak certs/ca-a/ca.srl
# ca-b's key is not needed once its cert exists; ca-a's key is kept only to sign more fixtures
rm certs/ca-b/ca.key
