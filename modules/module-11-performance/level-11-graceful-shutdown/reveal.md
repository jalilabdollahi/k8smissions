**Cause 1: the worker is not PID 1.** The container runs `sh -c "echo ...; python -u /app/worker.py; echo ..."`. The shell stays as PID 1 and has no SIGTERM handler, so the signal is dropped and the Python worker (its child) never sees it. The pod then lingers until the grace period ends and SIGKILL arrives. Run the worker directly (`command: ["python","-u","/app/worker.py"]`), or keep a wrapper but end it with `exec python ...`.

**Cause 2: 15 seconds is shorter than a clip.** Even with the signal delivered, a 25 second clip cannot finish in 15 seconds. Set `terminationGracePeriodSeconds` above the longest clip (40 leaves margin).

    kubectl patch deployment video-transcoder -n k8smissions --type=json -p '[
      {"op":"replace","path":"/spec/template/spec/containers/0/command","value":["python","-u","/app/worker.py"]},
      {"op":"replace","path":"/spec/template/spec/terminationGracePeriodSeconds","value":40}]'
