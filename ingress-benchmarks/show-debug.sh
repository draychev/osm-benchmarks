#!/bin/bash

## Stream Bookbuyer Logs
POD="$(kubectl get pods -n bookbuyer --show-labels --selector app=bookbuyer --no-headers | grep -v 'Terminating' | awk '{print $1}' | head -n1)"

kubectl logs "${POD}" -n bookbuyer -c bookbuyer --tail=100

## Stream Bookbuyer Logs
kubectl logs --selector app=bookbuyer -n bookbuyer -c bookbuyer --tail=100  | grep 'Identity'

kubectl get ingress -A

##IP=$(kubectl get services -n ingress-contour contour-envoy -o json | jq -r '.status.loadBalancer.ingress[0].ip')
IP=$(kubectl get ingress -A --no-headers | grep osm-bookstore.contoso.com | awk '{print $5}')
while true; do
    curl -X GET -I -H "Host: osm-bookstore.contoso.com" http://${IP}/
    sleep 3
done
