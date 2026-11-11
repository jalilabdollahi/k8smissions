#!/bin/bash
# private repository on the in-cluster Git server (basic auth: ci-bot / ci-bot-secret)
PRIVATE=1 ../../module-7-gitops/_fixtures/gitserver/seed.sh payments-ci repo "payments-ci: build definition 4.18.2"
