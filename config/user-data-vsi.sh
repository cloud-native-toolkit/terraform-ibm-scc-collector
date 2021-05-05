#!/bin/bash

# Disable password authentication
# Whether commented or not, make sure they are uncommented and explicitly set to 'no'
grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
grep -q "PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# If any other files are Included, comment out the Include
# Sometimes IBM stock images have an uppercase Include like this.
sed -i "s/^Include/# Include/g" /etc/ssh/sshd_config

service ssh restart

# As a precaution, delete the root password in case it exists
passwd -d root

apt-get -y update
apt-get -y upgrade

sleep 60
mkdir /root/scc

# install docker compose
apt-get install -y docker-compose

cat > /usr/local/bin/scc-collector.sh << 'EOF'
REGISTRATION_KEY="$1"
if [[ -z "${REGISTRATION_KEY}" ]]; then
  echo "REGISTRATION_KEY is required as the first argument"
  exit 1
fi

#!/bin/bash
echo "**********"
echo "Downloading SCC installer"

# Install the collector
export controller="https://private.asap.compliance.cloud.ibm.com"
controller="https://private.asap.compliance.cloud.ibm.com"
repourl="private.icr.io/posture-management/compliance-collector"
tag="0.0.1"
watch_tower="private.icr.io/posture-management/compliance-watchtower:0.0.1"
export IBM_REPO_URL=${repourl}
export IBM_TAG=${tag}
export IBM_WATCH_TOWER_IMAGE=${watch_tower}
export controller=${controller}

curl -Lo /tmp/scc-installer.sh $controller/internal/v1/collector/scripts/get-installer
chmod +x /tmp/scc-installer.sh

echo "**********"
echo "SCC installer help"
/tmp/scc-installer.sh --help

echo "**********"
echo "Running: ./scc-installer.sh -k ${REGISTRATION_KEY} -e 'null' -m /root/scc"

/tmp/scc-installer.sh -k ${REGISTRATION_KEY} -e 'null' -m /root/scc
EOF

chmod +x /usr/local/bin/scc-collector.sh
