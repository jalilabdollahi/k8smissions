#!/bin/bash
# Large answers fall back to TCP; the policy only lets UDP 53 through.
kubectl patch networkpolicy price-feed-egress -n k8smissions --type=json \
  -p '[{"op":"add","path":"/spec/egress/0/ports/-","value":{"protocol":"TCP","port":53}}]'
sleep 3
