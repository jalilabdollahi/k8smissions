#!/bin/bash
# private repository whose only branch is master, and a plain in-cluster registry
PRIVATE=1 ../../module-7-gitops/_fixtures/gitserver/seed.sh payments-api repo "payments-api: build context"
kubectl -n gitops-git exec -c gitserver deploy/gitserver -- sh -c '
  g=/srv/git/private/payments-api.git
  git --git-dir=$g branch -m main master && git --git-dir=$g symbolic-ref HEAD refs/heads/master'
../_fixtures/registry.sh
