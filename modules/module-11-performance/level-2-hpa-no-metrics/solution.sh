#!/bin/bash
# Utilisation is usage / request per container; log-shipper has no CPU request, so the HPA has no denominator.
kubectl set resources deployment/thumbnailer -n k8smissions -c log-shipper --requests=cpu=10m,memory=16Mi
kubectl rollout status deployment/thumbnailer -n k8smissions --timeout=90s
