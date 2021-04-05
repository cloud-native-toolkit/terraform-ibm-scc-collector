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

