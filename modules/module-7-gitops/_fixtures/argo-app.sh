#!/bin/bash
# Create Argo CD Application(s) from a manifest file and label them k8smissions/managed=true
# (the engine's cleanup deletes labelled Applications). Replaces a stale Application of the same name.
# Usage: argo-app.sh FILE   (run from a level's setup.sh)
set -e
for n in $(kubectl apply --dry-run=client -f "$1" -o name | sed 's#.*/##'); do
  kubectl -n argocd delete application "$n" --ignore-not-found --wait >/dev/null
done
for o in $(kubectl apply -f "$1" -o name); do
  kubectl -n argocd label "$o" k8smissions/managed=true --overwrite >/dev/null
done
