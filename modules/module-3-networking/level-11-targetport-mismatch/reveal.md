1. The EndpointSlice for `checkout` has three addresses but no ports: the Service asks for a container port named `http`, and the 4.2 pods call it `app-http`, so there is nothing to connect to.
2. Point the Service at the name the pods now use (a number, 8080, also works):

   `kubectl -n k8smissions patch svc checkout --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":"app-http"}]'`

3. Requests are answered by 4.2 again; no pod needs to restart. Rolling back with `kubectl rollout undo` would make the Service work but would bring back 4.1.
