# Sample handler: mutating webhook that adds the label labeler/injected=true to Pods.
def mutate(req):
    labels = req["object"]["metadata"].get("labels")
    if labels is None:
        return True, "", [{"op": "add", "path": "/metadata/labels", "value": {"labeler/injected": "true"}}]
    return True, "", [{"op": "add", "path": "/metadata/labels/labeler~1injected", "value": "true"}]
