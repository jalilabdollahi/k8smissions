#!/bin/bash
kubectl -n k8smissions get pipelinerun ship-ledger-0612 -o jsonpath='{.status.childReferences}'; echo
kubectl -n k8smissions logs -l tekton.dev/pipelineTask=unit-tests --all-containers --tail=20
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: unit-tests
spec:
  params:
  - name: suite
    type: string
  steps:
  - name: test
    image: busybox:1.36
    onError: continue
    script: |
      #!/bin/sh
      echo "running suite $(params.suite)"
      case "$(params.suite)" in
        regression)
          echo "FAIL ledger_rounding_test: expected 10.01, got 10.00"
          echo "FAIL ledger_fx_cents_test: expected 3.35, got 3.34"
          echo "2 failed, 38 passed"
          exit 1
          ;;
        *)
          echo "12 passed"
          ;;
      esac
  - name: report
    image: busybox:1.36
    script: |
      #!/bin/sh
      code=$(cat $(steps.step-test.exitCode.path))
      echo "test step exit code: $code"
      echo "report: archived test summary for ledger"
      exit "$code"
YAML
