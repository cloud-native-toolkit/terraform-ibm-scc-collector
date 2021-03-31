module "vpcssh" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-ssh.git"

  resource_group_name = var.resource_group_name
  region              = var.region
  name_prefix         = var.name_prefix
  ibmcloud_api_key    = var.ibmcloud_api_key
}
