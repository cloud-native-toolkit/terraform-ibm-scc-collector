#!/bin/bash

REGISTRATION_KEY="$1"
if [[ -z "${REGISTRATION_KEY}" ]]; then
  REGISTRATION_KEY=${scc_registration_key}
fi

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

echo "**********"
echo "SCC installer logic"
cat /tmp/scc-installer.sh

echo "**********"
echo "SCC installer help"
/tmp/scc-installer.sh --help

echo "**********"
echo "Running: /tmp/scc-installer.sh -k ${REGISTRATION_KEY} -e 'null' -m /root/scc"

/tmp/scc-installer.sh -k "${REGISTRATION_KEY}" -e 'null' -m /root/scc
