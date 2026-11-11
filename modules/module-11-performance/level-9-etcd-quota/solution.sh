#!/bin/bash
# The exporter labels its results app=exporter but its cleanup deletes app=exporter-output, so it never
# deletes anything. Make new results carry the label the cleanup looks for, then remove the old pile.
kubectl get configmap exporter-script -n k8smissions -o yaml \
  | sed 's/{"app": "exporter"}/{"app": "exporter-output"}/' | kubectl apply -f -
# billing-web mounts export-result-0042: keep it, delete the other old results.
kubectl delete configmap -n k8smissions -l app=exporter --field-selector=metadata.name!=export-result-0042
