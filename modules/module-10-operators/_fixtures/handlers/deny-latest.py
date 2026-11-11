# Sample handler: validating policy that denies images tagged :latest (or untagged) on Pods.
def validate(req):
    pod = req["object"]
    for c in pod["spec"].get("containers", []):
        img = c["image"].split("/")[-1]
        if ":" not in img or img.endswith(":latest"):
            return False, "policy-guard: image %s must use a pinned tag" % c["image"]
    return True, ""
