#!/bin/bash
# data-app runs the shared uploader; its source is loaded into ConfigMap uploader-src first.
kubectl delete configmap uploader-src -n "$NS" --ignore-not-found >/dev/null
kubectl create configmap uploader-src -n "$NS" --from-file=app.py=../_fixtures/uploader.py
