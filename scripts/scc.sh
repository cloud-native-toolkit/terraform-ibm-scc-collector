#!/bin/bash

REGISTRATION_KEY="$1"
if [[ -z "${REGISTRATION_KEY}" ]]; then
  echo "REGISTRATION_KEY is required as the first argument"
  exit 1
fi

echo "**********"
echo "Downloading SCC installer"

# Install the collector
export controller="https://private.asap.compliance.cloud.ibm.com"
curl -Lo /tmp/scc-installer.sh $controller/internal/v1/collector/scripts/get-installer
chmod +x /tmp/scc-installer.sh

echo "**********"
echo "SCC installer help"
/tmp/scc-installer.sh --help

echo "**********"
echo "Running: ./scc-installer.sh -k ${REGISTRATION_KEY} -e 'null' -m /root/scc"

/tmp/scc-installer.sh -k ${REGISTRATION_KEY} -e 'null' -m /root/scc
