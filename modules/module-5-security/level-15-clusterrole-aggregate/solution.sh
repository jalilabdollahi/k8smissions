kubectl get clusterrole ticket-viewer -o yaml
kubectl get clusterrole -L aggregate-to-ticket-viewer --show-labels | grep ticket
kubectl label clusterrole ticket-jobs aggregate-to-ticket-viewer=true --overwrite
kubectl label clusterrole ticket-events aggregate-to-ticket-viewer=true
sleep 3
kubectl get clusterrole ticket-viewer -o jsonpath='{.rules}'
