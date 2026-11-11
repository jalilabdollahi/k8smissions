#!/bin/bash
# Add one commit to an existing repo: the files in SRC_DIR are written over the current tree.
# Delete files with DELETE="path1 path2". Usage: [DELETE="a b"] commit.sh NAME SRC_DIR MESSAGE
set -e
name=$1 src=$2 msg=$3
tar -C "$src" -cf - . | kubectl -n gitops-git exec -i -c gitserver deploy/gitserver -- sh -c '
  set -e
  w=$(mktemp -d); git clone -q /srv/git/$3$1.git "$w/r"; cd "$w/r"
  tar -xf - ; for f in $4; do git rm -q -r --ignore-unmatch "$f"; done
  git add -A
  git -c user.name=seed -c user.email=seed@gitops.local commit -q -m "$2"
  git push -q origin main; rm -rf "$w"' sh "$name" "$msg" "${PRIVATE:+private/}" "${DELETE:-}" 2>&1 | sed 's/^/commit: /' >&2
