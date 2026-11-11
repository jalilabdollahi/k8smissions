## What was broken

Task `clone` fetches the private repository `payments-ci` over HTTP basic auth. The credentials existed as Secret `ci-git` and were attached to ServiceAccount `ci-runner`, but two things kept Tekton from using them. The PipelineRun was running as `default`, not as `ci-runner`. And the Secret's `tekton.dev/git-0` annotation named `https://gitserver.gitops-git.svc.cluster.local`, whereas the repository is served over `http` on port 8080.

## The evidence

The step log showed Git asking for a username it could not get (terminal prompts are disabled in a pod). `kubectl get pipelinerun -o yaml` had no `serviceAccountName`, so it ran as `default`; `kubectl describe sa ci-runner` showed the Secret was on another account. The annotation and the clone URL, side by side, differed in scheme and port.

## Why Tekton behaved this way

Before the steps start, Tekton's init step looks at the Secrets of the TaskRun's ServiceAccount and writes Git credentials for those whose annotation URL matches. Git then sends them to hosts that match. A Secret on the wrong ServiceAccount, or with a non-matching annotation, is skipped without an error, and the clone fails later as an anonymous request.

## The fix

Annotate the Secret with the exact `http://host:8080` URL and start a new run with `taskRunTemplate.serviceAccountName: ci-runner`. Run specs are immutable, so the old run cannot be repaired. The Secret stays `kubernetes.io/basic-auth` and the password never appears in a URL, a Pipeline or a log.

## In production

Use one canonical Git URL per server, and set the ServiceAccount for a Pipeline in the trigger or in `config-defaults`, so that nobody has to remember it. Prefer deploy keys or short-lived tokens.

## Commands worth remembering

- `kubectl describe sa NAME`
- `kubectl get secret NAME -o jsonpath='{.metadata.annotations}'`
- `kubectl explain pipelinerun.spec.taskRunTemplate`
