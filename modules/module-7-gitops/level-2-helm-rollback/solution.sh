NS=k8smissions
helm -n $NS history webapp
for r in 1 2 3 4; do echo "--- revision $r"; helm -n $NS get manifest webapp --revision $r | grep -E 'payload|body|webapp v' ; done
helm -n $NS rollback webapp 2 --wait --timeout 90s
helm -n $NS status webapp
