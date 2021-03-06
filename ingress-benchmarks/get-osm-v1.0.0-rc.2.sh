#!/bin/bash

set -auexo pipefail

RELEASE="v1.0.0-rc.2"
curl -L https://github.com/openservicemesh/osm/releases/download/${RELEASE}/osm-${RELEASE}-linux-amd64.tar.gz | tar -vxzf -

mv ./linux-amd64/osm ./
rm -rf ./linux-amd64/osm
