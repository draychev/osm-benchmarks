#!/bin/bash

set -auexo pipefail

## Just making sure we don't make a mess on the same cluster
kubectx three

OSM_NAMESPACE="${OSM_NAMESPACE:-osm-system}"

BOOKBUYER_NAMESPACE='bookbuyer'
BOOKSTORE_NAMESPACE='bookstore'

# Cleanup
kubectl delete namespace $(kubectl get namespaces --no-headers | awk '{print $1}' | grep -E '^book') --wait || true

kubectl create namespace bookbuyer
kubectl create namespace bookstore

osm namespace add bookbuyer
osm namespace add bookstore

########################################

# Enable SMI mode
echo -e "Enable SMI mode (permissiveTrafficPolicyMode = false"
kubectl patch meshconfig osm-mesh-config \
  --namespace $OSM_NAMESPACE \
  --patch '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":false}}}' \
  --type=merge

########################################

osm namespace remove ingress-nginx

# Install Nginx Ingress Controller in the defualt namespace
helm upgrade \
  --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

### Annotate NGINX Ingress Controller with this
### kubectl annotate pod <pod> -n ingress-nginx openservicemesh.io/inbound-port-exclusion-list=80,443,10254
kubectl patch deployment -n ingress-nginx ingress-nginx-controller -p '{"spec":{"template":{"metadata":{"annotations":{"openservicemesh.io/inbound-port-exclusion-list": "80,443,10254"}}}}}'
kubectl patch meshconfig osm-mesh-config -n osm-system -p '{"spec":{"traffic":{"inboundPortExclusionList":[80,443,10254]}}}'  --type=merge
kubectl patch deployment -n ingress-nginx ingress-nginx-controller -p '{"spec":{"template":{"metadata":{"annotations":{"openservicemesh.io/outbound-port-exclusion-list": "80,443,10254"}}}}}'
kubectl patch meshconfig osm-mesh-config -n osm-system -p '{"spec":{"traffic":{"outboundPortExclusionList":[80,443,10254]}}}'  --type=merge

### WE ADD THE NGINX NAMESPACE TO THE MESH
osm namespace add ingress-nginx

kubectl rollout restart -n ingress-nginx deployment ingress-nginx-controller

kubectl delete ValidatingWebhookConfiguration ingress-nginx-admission

sleep 5


kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bookstore
  namespace: bookstore
  annotations:
    nginx.ingress.kubernetes.io/service-upstream: "true"
    nginx.ingress.kubernetes.io/upstream-vhost: bookstore.bookstore.svc.cluster.local
spec:
  ingressClassName: nginx
  rules:
  - host: osm-bookstore.contoso.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: bookstore
            port:
              number: 14001
EOF

#########################################33

./deploy-apps.sh
./show-debug.sh
