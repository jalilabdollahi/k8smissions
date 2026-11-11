#!/bin/bash
NS=${NS:-k8smissions}

if kubectl get ns payments-sandbox >/dev/null 2>&1; then
  phase=$(kubectl get ns payments-sandbox -o jsonpath='{.status.phase}' 2>/dev/null)
  echo "❌ namespace payments-sandbox still exists (${phase:-unknown})"
  exit 1
fi
if kubectl -n argocd get application payments-sandbox >/dev/null 2>&1; then
  echo "❌ Application payments-sandbox still exists"
  exit 1
fi
echo "✅ namespace payments-sandbox and its Application are gone"

down=$(kubectl get apiservice -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.status.conditions[?(@.type=="Available")].status}{"\n"}{end}' 2>/dev/null | grep '=False$' | cut -d= -f1)
if [ -n "$down" ]; then
  echo "❌ API services still unavailable: $(echo $down | tr '\n' ' ')"
  exit 1
fi
echo "✅ every registered API service is Available"

want=$(kubectl get ns keep-me -o jsonpath='{.metadata.annotations.k8smissions/probe-uid}' 2>/dev/null)
uid=$(kubectl -n keep-me get pod probe -o jsonpath='{.metadata.uid}' 2>/dev/null)
phase=$(kubectl -n keep-me get pod probe -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$want" ] || [ "$uid" != "$want" ] || [ "$phase" != "Running" ]; then
  echo "❌ the pod in keep-me was disturbed (phase ${phase:-gone})"
  exit 1
fi
echo "✅ keep-me/probe is untouched and Running"
exit 0
exit 1
