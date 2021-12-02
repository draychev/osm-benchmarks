# ingress-benchmarks

This document shows benchmark results from the following 3 scenarious:

1. Contour + OSM - Contour is given an mTLS certificate to participate in the mesh
2. Nginx + OSM - Nginx is given an mTLS cert
3. Nginx inside OSM - Nginx is installed in a namespace, which participates in the mesh and is sidecared with an Envoy proxy (one pod 2 proxies - one Nginx, one Envoy)


The experiment was ran on 3 unique AKS clusters with the same characteristics.
1. run--ingress--contour.sh
2. run--ingress--nginx.sh
3. run--ingress--nginx-inmesh.sh

We issue 1000 cURL commands using:
```bash
for x in $(seq 1000); do
    curl -X GET -I -H "Host: osm-bookstore.contoso.com" http://${IP}/
done
```

The `cURL` command is configured with `~/.curlrc`:
```shell
-w "dnslookup: %{time_namelookup} | connect: %{time_connect} | appconnect: %{time_appconnect} | pretransfer: %{time_pretransfer} | starttransfer: %{time_starttransfer} | total: %{time_total} | size: %{size_download}\n"
```
| scenario | conn | pre | start | total |
|-------|---|---|---|--|
|NGINX Inside the Mesh| 0.187595| 0.187654| 0.383522| 0.383575|
|NGINX Outside the Mesh| 0.184945| 0.185003| 0.371933| 0.371986|
|Contour Outside the Mesh| 0.18523| 0.18529| 0.372467| 0.372521|
