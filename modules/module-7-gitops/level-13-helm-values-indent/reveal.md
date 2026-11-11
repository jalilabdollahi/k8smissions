1. The new pods pull `hashicorp/http-echo:1`, which does not exist. `helm get manifest search | grep image:` shows the rendered tag, while `values-prod.yaml` says `tag: 1.0`.
2. YAML reads an unquoted `1.0` as the number one, and Helm renders it as `1`. `helm get values search` shows it too (`tag: 1`).
3. Quote the value in `values-prod.yaml` (`tag: "1.0"`), or use `--set-string image.tag=1.0`. `--set image.tag=1.0` does not help.
4. Preview with `helm template search chart -f values-prod.yaml | grep image:`, then `helm upgrade search chart -f values-prod.yaml` and wait for the rollout.
