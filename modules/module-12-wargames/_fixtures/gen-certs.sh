#!/bin/bash
# Documents how certs/ was made. NOT run by any level; the PEMs are committed so results never change.
# Needs OpenSSL 3.4+ (x509 -not_before/-not_after) and module 10's CA key (read-only reuse).
# certs/ledger-expired : serverAuth leaf for ledger.k8smissions.svc, valid 2024-01-01..2024-04-01 (always expired)
# certs/gateway-expired: clientAuth leaf CN=gateway-client, same dates
# certs/ca.crt         : module 10's ca-a certificate (the "internal CA" of l9; its key is put in Secret internal-ca)
