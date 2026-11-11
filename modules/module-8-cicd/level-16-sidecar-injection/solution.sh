#!/bin/bash
kubectl -n k8smissions logs -l tekton.dev/pipelineRun=db-test-0812 --all-containers --tail=5
kubectl -n k8smissions patch task db-test --type=json -p '[
  {"op":"replace","path":"/spec/steps/0/script","value":"#!/bin/sh\nset -e\nn=0\nuntil curl -sf --max-time 2 http://127.0.0.1:$(params.db-port)/rows.txt > /tmp/rows.txt; do\n  n=$((n + 1))\n  if [ \"$n\" -ge 30 ]; then echo \"database not reachable after 30 attempts\"; exit 1; fi\n  sleep 1\ndone\nprintf \"%s\" \"$(wc -l < /tmp/rows.txt | tr -d \" \")\" > $(results.rows.path)\necho \"query returned $(cat $(results.rows.path)) rows\"\n"}]'
