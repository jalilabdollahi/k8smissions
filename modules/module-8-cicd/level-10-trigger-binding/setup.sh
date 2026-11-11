#!/bin/bash
# public repository on the in-cluster Git server with two commits; the pushed one is the older of the two
../../module-7-gitops/_fixtures/gitserver/seed.sh webhook-app repo "webhook-app: first release"
mkdir -p /tmp/k8sm-hook-more.$$ && echo "second change" > /tmp/k8sm-hook-more.$$/CHANGELOG.md
../../module-7-gitops/_fixtures/gitserver/commit.sh webhook-app /tmp/k8sm-hook-more.$$ "webhook-app: changelog"
rm -rf /tmp/k8sm-hook-more.$$
