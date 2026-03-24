#!/bin/bash
set -euo pipefail
SELFHEAL=$(kubectl get application my-app -n argocd     -o jsonpath='{.spec.syncPolicy.automated.selfHeal}' 2>/dev/null || echo "not_found")
if [ "$SELFHEAL" = "false" ] || [ "$SELFHEAL" = "not_found" ]; then
  echo "PASS: selfHeal=false — manual changes persist"
  exit 0
fi
echo "FAIL: selfHeal=$SELFHEAL — ArgoCD will keep reverting manual changes"
exit 1
