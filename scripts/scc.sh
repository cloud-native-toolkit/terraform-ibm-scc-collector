#!/bin/bash

echo "**********"
echo "Waiting for boot to finish"
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 10
done

# make data directory
echo "**********"
echo "Waiting 60 seconds for the environment to settle"
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
echo "Running: ./scc-installer.sh -k ${scc_registration_key} -e 'null' -m /root/scc -p '' < 'n'"

./scc-installer.sh -k ${scc_registration_key} -e 'null' -m /root/scc -p "" < "n"
