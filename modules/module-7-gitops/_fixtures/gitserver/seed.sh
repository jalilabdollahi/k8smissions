#!/bin/bash
# Create (or replace) a repo on the Git server from a directory tree, with one commit on branch main.
# Usage: seed.sh NAME SRC_DIR [COMMIT_MESSAGE]
#   PRIVATE=1 seed.sh ...  puts it under /srv/git/private (needs basic auth, module 8)
# Starts the server first if it is not running. Run from a level's setup.sh.
set -e
d=$(cd "$(dirname "$0")" && pwd)
name=$1 src=$2 msg=${3:-"initial import"}
"$d/up.sh"
dir=/srv/git/${PRIVATE:+private/}$name.git
tar -C "$src" -cf - . | kubectl -n gitops-git exec -i -c gitserver deploy/gitserver -- sh -c '
  set -e
  w=$(mktemp -d); tar -C "$w" -xf -; cd "$w"
  git init -q -b main
  git add -A
  git -c user.name=seed -c user.email=seed@gitops.local commit -q -m "$2"
  rm -rf "$3"; mkdir -p "$3"; git init -q --bare -b main "$3"
  git push -q "$3" main
  rm -rf "$w"' sh "$d" "$msg" "$dir" 2>&1 | sed 's/^/seed: /' >&2
