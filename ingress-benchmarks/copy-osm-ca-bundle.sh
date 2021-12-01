#!/bin/bash

kubectl get secret -n osm-system osm-ca-bundle -o yaml > osm-ca-bundle.yaml
perl -p -i -e 's/namespace: osm-system/namespace: bookstore/g' osm-ca-bundle.yaml
kubectl apply -f osm-ca-bundle.yaml
rm -rf osm-ca-bundle.yaml
