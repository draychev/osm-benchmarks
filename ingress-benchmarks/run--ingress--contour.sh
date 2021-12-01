#!/bin/bash

set -auexo pipefail

## Just making sure we don't make a mess on the same cluster
kubectx one

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


./deploy-apps.sh

kubectl annotate \
        service bookstore -n bookstore \
        projectcontour.io/upstream-protocol.tls='14001' \
        --overwrite

./copy-osm-ca-bundle.sh

########################################


# Install Contour Ingress Controller in the defualt namespace
kubectl create namespace ingress-contour || true
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade \
  --install contour bitnami/contour \
  --namespace ingress-contour \
  --create-namespace \
  --version 4.3.9

if [ $? != 0 ]; then
 echo "Error installing Contour."
 exit 1
fi

# Either patch or edit the config map and add the TLS params below
kubectl patch ConfigMap contour \
        -n ingress-contour \
        -p '{"data":{"contour.yaml":{"tls":"envoy-client-certificate":{"name":"osm-ingress-mtls","namespace":"ingress-contour"}}}}' \
        --type=merge || true

# Here is the Contour ConfigMap
### data:
###   contour.yaml: |
###     accesslog-format: envoy
###     disablePermitInsecure: false
###     envoy-service-name: 'contour-envoy'
###     leaderelection:
###       configmap-namespace: 'ingress-contour'
###     tls:
###       fallback-certificate: null
###       envoy-client-certificate:
###         name: osm-ingress-mtls
###         namespace: ingress-contour

kubectl label namespace ingress-contour openservicemesh.io/monitored-by=osm --overwrite=true

kubectl rollout restart -n ingress-contour deployment contour-contour


# Remove the old cert -- OSM will create a new one
kubectl delete secret -n ingress-contour osm-ingress-mtls || true

kubectl patch MeshConfig \
  osm-mesh-config \
  --namespace $OSM_NAMESPACE \
  --patch '{"spec":{"certificate":{"ingressGateway":{"subjectAltNames":["ingress-contour.ingress-contour.cluster.local"], "validityDuration":"24h", "secret":{"name":"osm-ingress-mtls","namespace":"ingress-contour"}}}}}' \
  --type=merge


kubectl apply -f - <<EOF
---
apiVersion: projectcontour.io/v1
kind: TLSCertificateDelegation
metadata:
  name: ca-secret
  namespace: ingress-contour
spec:
  delegations:
    - secretName: osm-ca-bundle
      targetNamespaces:
      - bookstore
---
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: bookstore
  namespace: bookstore
spec:
  virtualhost:
    fqdn: osm-bookstore.contoso.com
  routes:
  - services:
    - name: bookstore
      port: 14001
      validation:
        caSecret: osm-ca-bundle
        subjectName: bookstore.bookstore.cluster.local
---
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
      skipClientCertValidation: false
  sources:
  - kind: Service
    name: contour-envoy
    namespace: ingress-contour
  - kind: AuthenticatedPrincipal
    name: ingress-contour.ingress-contour.cluster.local
EOF

#########################################33

./show-debug.sh
