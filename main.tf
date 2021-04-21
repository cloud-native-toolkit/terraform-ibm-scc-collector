locals {
  ubuntu_image = "ibm-ubuntu-18-04-1-minimal-amd64-2"
  user_data_vsi_file = "${path.module}/config/user-data-vsi.sh"
  user_data_vsi = data.local_file.user_data_vsi.content
  resource_group_id = var.resource_group_id
}

resource null_resource print-names {
  provisioner "local-exec" {
    command = "echo 'VPC name: ${var.vpc_name}'"
  }
}

data ibm_is_vpc vpc {
  depends_on = [null_resource.print-names]

  name  = var.vpc_name
}

data local_file user_data_vsi {
  filename = local.user_data_vsi_file
}

data "ibm_is_image" "ubuntu_image" {
    name = local.ubuntu_image
}

resource "ibm_is_security_group" "vsi_sg" {
    name           = "${var.vpc_name}-sg-scc"
    vpc            = data.ibm_is_vpc.vpc.id
    resource_group = local.resource_group_id
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
  count = var.vpc_subnet_count

  name           = "${var.vpc_name}-scc${count.index + 1}"
  resource_group = local.resource_group_id
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ubuntu_image.id
  vpc            = data.ibm_is_vpc.vpc.id
  keys           = [var.ssh_key_id]
  zone           = var.vpc_subnets[count.index].zone
  user_data      = local.user_data_vsi

  primary_network_interface {
    subnet          = var.vpc_subnets[count.index].id
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
  count = var.vpc_subnet_count

  name           = "${var.vpc_name}-scc${count.index + 1}-fip"
  target         = ibm_is_instance.vsi[count.index].primary_network_interface[0].id
  resource_group = var.resource_group_id
}
  
# Setup scc
resource "null_resource" "setup_scc" {
  count = var.vpc_subnet_count
  depends_on = [ibm_is_floating_ip.vsi_floatingip]

  connection {
    type        = "ssh"
    user        = "root"
    password    = ""
    private_key = var.ssh_private_key
    host        = ibm_is_floating_ip.vsi_floatingip[count.index].address
  }

  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline     = [
      "chmod +x /tmp/*.sh",
      "/tmp/scc.sh ${var.scc_registration_key}"
    ]
  }
}  
