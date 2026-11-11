kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=5
kubectl -n k8smissions apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
  namespace: k8smissions
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: shop.k8sm.local
    http:
      paths:
      - path: /shop(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: storefront
            port:
              number: 80
YAML
sleep 5
