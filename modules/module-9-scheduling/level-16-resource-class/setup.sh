#!/bin/bash
# What a DRA driver would publish: one ResourceSlice per worker with a single GPU. kind has no driver, so they are written by hand.
. ../_fixtures/lib.sh
i=0
for n in $(workers); do
  i=$((i+1))
  kubectl apply -f - <<YAML
apiVersion: resource.k8s.io/v1
kind: ResourceSlice
metadata:
  name: gpu-lab-slice-$i
  labels:
    k8smissions/managed: "true"
spec:
  driver: gpu.lab.example.net
  nodeName: $n
  pool:
    name: $n
    generation: 1
    resourceSliceCount: 1
  devices:
  - name: gpu-$i
    attributes:
      model:
        string: t4
    capacity:
      memory:
        value: 16Gi
YAML
done
