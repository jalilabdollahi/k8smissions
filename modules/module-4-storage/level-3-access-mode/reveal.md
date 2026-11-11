# Reveal

The claim `site-content` is ReadWriteOnce and backed by a node-local volume, so every pod that mounts it must run on that one node. The Deployment also has a hard topology spread constraint (`maxSkew: 1`, `DoNotSchedule`) that forbids more than one replica on a node while other nodes are empty. The second and third replica satisfy neither rule.

1. See it: `kubectl get pods -o wide` shows one Running pod; `kubectl describe pod` on a Pending one lists `didn't match pod topology spread constraints` and `volume node affinity conflict`.
2. Make the spread rule soft, so replicas may share the volume's node:

   ```bash
   kubectl patch deployment web-servers -n k8smissions --type=json \
     -p '[{"op":"replace","path":"/spec/template/spec/topologySpreadConstraints/0/whenUnsatisfiable","value":"ScheduleAnyway"}]'
   ```
   (Removing the constraint also works.)
3. The three replicas now start on the node that owns the volume.
