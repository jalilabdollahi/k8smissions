**Deleting the ValidatingWebhookConfiguration.** Creates are instant and the symptom is gone, but the policy `config-guard` enforces is gone with it. The validator creates a ConfigMap labelled `unreviewed=true` and expects the webhook's own refusal.

**Setting `failurePolicy: Ignore` or lowering `timeoutSeconds`.** That makes the failure faster or silent, but the backend is still unreachable and the rejection check fails, since an ignored webhook enforces nothing. Fix the Service and the CA instead.

**Fixing the backend and stopping.** When creates start failing in milliseconds instead of ten seconds it feels like progress, but the new error (`certificate signed by unknown authority`) is a separate fault in `caBundle`. And the noisy client keeps doing most of the API traffic until its interval is raised.
