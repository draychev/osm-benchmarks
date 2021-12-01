#!/bin/bash

set -auexo pipefail

## Just making sure we don't make a mess on the same cluster
kubectx two

OSM_NAMESPACE="${OSM_NAMESPACE:-osm-system}"

BOOKBUYER_NAMESPACE='bookbuyer'
BOOKSTORE_NAMESPACE='bookstore'

# Cleanup
# kubectl delete namespace $(kubectl get namespaces --no-headers | awk '{print $1}' | grep -E '^book') --wait || true

kubectl create namespace bookbuyer || true
kubectl create namespace bookstore || true

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


# Install Nginx Ingress Controller in the defualt namespace
# helm upgrade \
#   --install ingress-nginx ingress-nginx \
#   --repo https://kubernetes.github.io/ingress-nginx \
#   --namespace ingress-nginx \
#   --create-namespace

kubectl label namespace ingress-nginx openservicemesh.io/monitored-by=osm --overwrite=true


# Remove the old cert -- OSM will create a new one
kubectl delete secret -n ingress-nginx osm-ingress-mtls || true

kubectl patch MeshConfig \
  osm-mesh-config \
  --namespace $OSM_NAMESPACE \
  --patch '{"spec":{"certificate":{"ingressGateway":{"subjectAltNames":["ingress-nginx.ingress-nginx.cluster.local"], "validityDuration":"24h", "secret":{"name":"osm-ingress-mtls","namespace":"ingress-nginx"}}}}}' \
  --type=merge

kubectl rollout restart -n ingress-nginx deployment ingress-nginx-controller

kubectl delete ValidatingWebhookConfiguration ingress-nginx-admission || true

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bookstore
  namespace: bookstore
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    # proxy_ssl_name for a service is of the form <service-account>.<namespace>.cluster.local
    nginx.ingress.kubernetes.io/configuration-snippet: |
      proxy_ssl_name "bookstore.bookstore.cluster.local";
    nginx.ingress.kubernetes.io/proxy-ssl-secret: "ingress-nginx/osm-ingress-mtls"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
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


kubectl apply -f - <<EOF
apiVersion: policy.openservicemesh.io/v1alpha1
kind: IngressBackend
metadata:
  name: bookstore
  namespace: bookstore
spec:
  backends:
  - name: bookstore
    port:
      number: 14001
      protocol: https
    tls:
      skipClientCertValidation: true
  sources:
  - kind: Service
    name: ingress-nginx-controller
    namespace: ingress-nginx
  - kind: AuthenticatedPrincipal
    name: ingress-nginx.ingress-nginx.cluster.local
EOF

#########################################33

./deploy-apps.sh

./show-debug.sh
