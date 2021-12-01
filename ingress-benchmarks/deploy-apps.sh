#!/bin/bash

echo "Deploying ServiceAccount bookstore"
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookstore
  namespace: bookstore
EOF

echo "Deploying Service bookstore"
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: bookstore
  namespace: bookstore
spec:
  selector:
    app: bookstore-v1
  ports:
  - name: bookstore
    port: 14001
EOF

echo "Deploying Deployment bookstore-v1"
kubectl apply -f - <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bookstore-v1
  namespace: bookstore
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bookstore-v1
  template:
    metadata:
      labels:
        app: bookstore-v1
    spec:
      serviceAccountName: bookstore
      containers:
      - args:
        - --path
        - ./
        - --port
        - "14001"
        command:
        - /bookstore
        env:
        - name: IDENTITY
          value: bookstore-v1
        image: openservicemesh/bookstore:v1.0.0-rc.2
        imagePullPolicy: Always
        name: bookstore-v1
        ports:
        - containerPort: 14001
EOF

echo "Deploying ServiceAccount bookbuyer"
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bookbuyer
  namespace: bookbuyer
EOF

echo "Deploying Deployment bookbuyer"
kubectl apply -f - <<EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bookbuyer
  namespace: bookbuyer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bookbuyer
  template:
    metadata:
      labels:
        app: bookbuyer
    spec:
      serviceAccount: bookbuyer
      serviceAccountName: bookbuyer
      containers:
      - name: bookbuyer
        image: openservicemesh/bookbuyer:v1.0.0-rc.2
        imagePullPolicy: Always
        command:
        - /bookbuyer
        env:
        - name: BOOKSTORE_NAMESPACE
          value: bookstore
EOF

echo "Deploying HTTPRouteGroup bookstore-service-routes"
kubectl apply -f - <<EOF
---
apiVersion: specs.smi-spec.io/v1alpha4
kind: HTTPRouteGroup
metadata:
  name: bookstore-service-routes
  namespace: bookstore
spec:
  matches:
  - name: everything
    pathRegex: /.*
    methods:
    - GET
    - POST
    - PATCH
EOF

echo "Deploying TrafficTarget bookbuyer-access-bookstore"
kubectl apply -f - <<EOF
---
apiVersion: access.smi-spec.io/v1alpha3
kind: TrafficTarget
metadata:
  name: bookbuyer-access-bookstore
  namespace: bookstore
spec:

  destination:
    kind: ServiceAccount
    name: bookstore
    namespace: bookstore

  rules:
  - kind: HTTPRouteGroup
    name: bookstore-service-routes
    matches:
    - everything

  sources:

  - kind: ServiceAccount
    name: bookbuyer
    namespace: bookbuyer

  - kind: ServiceAccount
    name: ingress-nginx
    namespace: ingress-nginx
EOF
