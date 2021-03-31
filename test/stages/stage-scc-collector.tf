module "scc-collector" {
  source = "./module"

  resource_group_name      = var.resource_group_name
  region                   = var.region
  name_prefix              = var.name_prefix
  ibmcloud_api_key         = var.ibmcloud_api_key
  name_prefix              = var.name_prefix
  vpc_id                   = module.vpc.id
  ssh_key_id               = module.vpcssh.id
  ssh_private_key          = module.vpcssh.private_key
  scc_registration_key     = var.scc_registration_key
}
