locals {
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
    name = var.image_name
}

module "scc_vsi" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-vsi.git?ref=v1.6.0"

  resource_group_id = var.resource_group_id
  region            = var.region
  ibmcloud_api_key  = var.ibmcloud_api_key
  vpc_name          = var.vpc_name
  vpc_subnet_count  = var.vpc_subnet_count
  vpc_subnets       = var.vpc_subnets
  profile_name      = "cx2-2x4"
  ssh_key_id        = var.ssh_key_id
  kms_key_crn       = var.kms_key_crn
  kms_enabled       = var.kms_enabled
  init_script       = var.init_script != "" ? var.init_script : file("${path.module}/config/user-data-vsi.sh")
  create_public_ip  = false
  label             = "scc"
  allow_ssh_from    = "10.0.0.0/8"
  security_group_rules = [
    {
      name      = "private-network"
      direction = "outbound"
      remote    = "10.0.0.0/8"
    },
    {
      name      = "service-endpoints"
      direction = "outbound"
      remote    = "161.26.0.0/16"
    },
    {
      name      = "iaas-endpoints"
      direction = "outbound"
      remote    = "166.8.0.0/14"
    },
    {
      name      = "outbound-http"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name      = "outbound-https"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name      = "outbound-dns"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      udp = {
        port_min = 53
        port_max = 53
      }
    }
  ]
  base_security_group = var.base_security_group
}
