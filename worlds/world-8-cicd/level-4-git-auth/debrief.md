# Clone Denied

## What Was Broken
The TaskRun ran as ServiceAccount pipeline-sa which had no secrets. The git-clone Task had no credentials and received 'authentication required' from the private repo.

## The Fix
Create an SSH key secret and attach it to the ServiceAccount used by the pipeline.

## Why It Matters
Tekton catalogs tasks like git-clone use a convention: attach secrets to the ServiceAccount based on the annotated secret type. kubernetes.io/ssh-auth secrets with tekton.dev/git-* annotations are auto-mounted.

## Pro Tip
For public repos use no-auth. For private repos create: kubectl create secret generic git-ssh-key --from-file=ssh-privatekey=~/.ssh/id_rsa --type=kubernetes.io/ssh-auth -n k8smissions

## Concepts
Tekton, git-clone, SSH secret, ServiceAccount, private repo
