#!/bin/bash
kubectl -n k8smissions logs -l tekton.dev/pipelineRun=inventory-build-0905 -c step-resolve
kubectl -n k8smissions patch pipeline inventory-build --type=json -p '[
  {"op":"add","path":"/spec/tasks/0/workspaces","value":[{"name":"cache","workspace":"cache"}]}]'
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: compile
spec:
  workspaces:
  - name: cache
    optional: true
    description: dependency cache kept between builds
  results:
  - name: cache-hit
  steps:
  - name: resolve
    image: busybox:1.36
    script: |
      #!/bin/sh
      echo "cache workspace bound: $(workspaces.cache.bound)"
      DEPS="$(workspaces.cache.path)/inventory-deps"
      if [ -f "$DEPS/.complete" ]; then
        echo "dependencies restored from cache ($(ls "$DEPS" | wc -l) entries)"
        printf true > $(results.cache-hit.path)
      else
        echo "cache miss: resolving dependencies..."
        sleep 6
        mkdir -p "$DEPS"
        for i in 1 2 3; do echo "jar $i" > "$DEPS/dep-$i.jar"; done
        touch "$DEPS/.complete"
        printf false > $(results.cache-hit.path)
      fi
  - name: build
    image: busybox:1.36
    script: |
      #!/bin/sh
      echo "compiling inventory against $(workspaces.cache.path)/inventory-deps"
YAML
