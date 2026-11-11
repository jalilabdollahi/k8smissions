#!/bin/bash
kubectl -n k8smissions get pipelinerun,resourcequota
kubectl -n k8smissions delete pod,service -l app=scratch
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: integration-test
spec:
  params:
  - name: scenario
    type: string
    default: ok
  tasks:
  - name: provision
    taskSpec:
      results:
      - name: name
      steps:
      - name: create
        image: alpine/kubectl:1.36.0
        script: |
          #!/bin/sh
          set -e
          n=scratch-$(context.pipelineRun.name)
          kubectl apply -f - <<MANIFEST
          apiVersion: v1
          kind: Pod
          metadata:
            name: $n
            labels: {app: scratch, run: $(context.pipelineRun.name)}
          spec:
            terminationGracePeriodSeconds: 1
            containers:
            - name: db
              image: hashicorp/http-echo:0.2.3
              args: ["-listen=:5678", "-text=scratch-ok"]
          ---
          apiVersion: v1
          kind: Service
          metadata:
            name: $n
            labels: {app: scratch, run: $(context.pipelineRun.name)}
          spec:
            selector: {run: $(context.pipelineRun.name)}
            ports:
            - port: 5678
          MANIFEST
          kubectl wait --for=condition=Ready pod/$n --timeout=60s
      - name: load-fixture
        image: busybox:1.36
        script: |
          #!/bin/sh
          if [ "$(params.scenario)" = "bad-fixture" ]; then
            echo "fixture checksum mismatch, refusing to load"
            exit 1
          fi
          echo "fixture loaded"
          printf '%s' "scratch-$(context.pipelineRun.name)" > $(results.name.path)
  - name: smoke
    runAfter: ["provision"]
    params:
    - name: target
      value: $(tasks.provision.results.name)
    taskSpec:
      params:
      - name: target
      steps:
      - name: query
        image: busybox:1.36
        script: |
          #!/bin/sh
          out=$(wget -qO- -T 5 http://$(params.target):5678)
          echo "scratch answered: $out"
          [ "$out" = "scratch-ok" ]
  finally:
  - name: teardown
    taskSpec:
      steps:
      - name: delete
        image: alpine/kubectl:1.36.0
        script: |
          #!/bin/sh
          kubectl delete pod,service scratch-$(context.pipelineRun.name) --ignore-not-found
YAML
