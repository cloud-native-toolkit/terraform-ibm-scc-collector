#!/bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# make data directory
sleep 60
mkdir /root/scc

# install docker compose
apt-get install -y docker-compose

# Install the collector
export controller="https://private.asap.compliance.cloud.ibm.com"
bash <(curl $controller/internal/v1/collector/scripts/get-installer) --regcode ${scc_registration_key} --interface null --mount-volume /root/scc
