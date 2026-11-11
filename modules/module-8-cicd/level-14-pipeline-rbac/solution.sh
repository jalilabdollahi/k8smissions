#!/bin/bash
kubectl -n k8smissions logs -l tekton.dev/pipelineRun=orchestrate-nightly-3 --tail=3
kubectl -n k8smissions auth can-i create pipelineruns.tekton.dev --as=system:serviceaccount:k8smissions:dispatcher
kubectl -n k8smissions create role pipelinerun-dispatch --verb=create,get,list,watch --resource=pipelineruns.tekton.dev
kubectl -n k8smissions create rolebinding dispatcher-pipelinerun-dispatch --role=pipelinerun-dispatch --serviceaccount=k8smissions:dispatcher
kubectl -n k8smissions auth can-i get pipelineruns.tekton.dev --as=system:serviceaccount:k8smissions:dispatcher
