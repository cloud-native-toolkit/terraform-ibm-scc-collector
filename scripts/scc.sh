#!/bin/bash

until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

# make data directory
sleep 60
mkdir /root/scc

# install docker compose
apt-get install -y docker-compose

echo "**********"
echo "Downloading SCC installer"

# Install the collector
export controller="https://private.asap.compliance.cloud.ibm.com"
curl -Lo scc-installer.sh $controller/internal/v1/collector/scripts/get-installer
chmod +x scc-installer.sh

echo "**********"
echo "SCC installer logic"
cat scc-installer.sh

echo "**********"
echo "SCC installer help"
./scc-installer.sh --help

echo "**********"

./scc-installer.sh -k ${scc_registration_key} -e null -m /root/scc
