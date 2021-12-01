#!/bin/bash

## touch ~/.curlrc
# -w "dnslookup: %{time_namelookup} | connect: %{time_connect} | appconnect: %{time_appconnect} | pretransfer: %{time_pretransfer} | starttransfer: %{time_starttransfer} | total: %{time_total} | size: %{size_download}\n"

IP=$(kubectl get ingress bookstore -n bookstore -o json | jq -r '.status.loadBalancer.ingress[0].ip')
IP="20.53.198.139"
for x in $(seq 1000); do
    curl -X GET -I -H "Host: osm-bookstore.contoso.com" http://${IP}/
done

# Run this with:
## ./issue-10k-requests.sh | grep 'starttransfer:' | tee stats-nginx-inmesh.tsv
