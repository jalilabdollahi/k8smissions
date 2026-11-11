#!/bin/bash
# api: allow one pod down at a time. cache: a budget that tolerates its single pod restarting.
kubectl patch pdb orders-api -n k8smissions --type=merge -p '{"spec":{"minAvailable":null,"maxUnavailable":1}}'
kubectl patch pdb orders-cache -n k8smissions --type=merge -p '{"spec":{"minAvailable":null,"maxUnavailable":1}}'
kubectl get pdb -n k8smissions
