locals {
  ubuntu_image = "ibm-ubuntu-18-04-1-minimal-amd64-2"
  user_data_vsi = <<EOF
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

EOF
}

data "ibm_is_image" "ubuntu_image" {
    name = local.ubuntu_image
}

resource "ibm_is_subnet" "subnet_vsi" {
  name            = "${var.basename}-subnet-vsi"
  vpc             = var.vpc_id
  resource_group  = var.resource_group_id
  zone            = var.zone
  total_ipv4_address_count = 32
}

resource "ibm_is_security_group" "vsi_sg" {
    name = "${var.basename}-vsi-sg"
    vpc = var.vpc_id
    resource_group = var.resource_group_id
}

resource "ibm_is_security_group_rule" "rule-all-outbound" {
    group = ibm_is_security_group.vsi_sg.id
    direction = "outbound"
    remote = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "rule-ssh-inbound" {
    group = ibm_is_security_group.vsi_sg.id
    direction = "inbound"
    remote = "0.0.0.0/0"
    tcp {
        port_min = 22
        port_max = 22
    }
}

resource "ibm_is_instance" "vsi" {
  name           = "${var.basename}-vsi"
  resource_group = var.resource_group_id
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu_image.id
  vpc            = var.vpc_id
  keys           = var.ssh_key_id
  zone           = var.zone
  user_data      = local.user_data_vsi

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet_vsi.id
    security_groups = [ibm_is_security_group.vsi_sg.id]
  }

  # Don't respin the VSI if the startup script is updated.
  lifecycle {
    ignore_changes = [
      user_data
    ]
  }
}

resource "ibm_is_floating_ip" "vsi_floatingip" {
  name   = "${var.basename}-fip"
  target = ibm_is_instance.vsi.primary_network_interface.0.id
}
  
# Setup scc
resource "null_resource" "setup_scc" {
  depends_on = [ibm_is_floating_ip.vsi_floatingip]

  connection {
    type     = "ssh"
    user     = "root"
    password = ""
    private_key = file(var.ssh_private_key_file)
    host        = ibm_is_floating_ip.vsi_floatingip.address
  }

  
  provisioner "remote-exec" {
    inline     = [
        templatefile("${path.module}/scc.sh",{scc_registration_key = var.scc_registration_key})
    ]
  }
}  
