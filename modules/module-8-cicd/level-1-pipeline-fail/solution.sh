#!/bin/bash
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: build
spec:
  results:
  - name: version
    description: release version for the notes
  steps:
  - name: generate
    image: busybox:1.36
    script: |
      #!/bin/sh
      set -e
      major=2
      minor=9
      patch=$(( $(printf 'ledger-release' | wc -c) * 3 ))
      printf '%s.%s.%s' "$major" "$minor" "$patch" > $(results.version.path)
      echo "generated version $(cat $(results.version.path))"
  - name: publish
    image: busybox:1.36
    script: |
      #!/bin/sh
      if [ ! -f $(results.version.path) ]; then
        echo "publish: cannot open the version result: No such file or directory"
        exit 1
      fi
      echo "publishing release notes for $(cat $(results.version.path))"
YAML
