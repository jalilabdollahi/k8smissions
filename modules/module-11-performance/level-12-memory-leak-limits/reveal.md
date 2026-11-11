**profile-api leaks.** Its snapshot cache grows by about 2Mi per second because `CACHE_MAX_MB=0` means "never evict". Bound it, to something well under the 128Mi limit:

    kubectl set env deployment/profile-api -n k8smissions CACHE_MAX_MB=48

Memory then rises to the bound and stays flat. A larger limit would only delay the OOM kill.

**render-svc has a plateau above its limit.** It loads a fixed 180Mi template set at start and then stays at about 195Mi. A 128Mi limit can never hold that. Lowering `TEMPLATE_CACHE_MB` makes `/render` answer 500 (incomplete output), so the answer is more memory:

    kubectl set resources deployment/render-svc -n k8smissions --requests=memory=224Mi --limits=memory=288Mi
