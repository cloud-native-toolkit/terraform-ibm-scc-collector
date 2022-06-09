module "scc-collector" {
  source = "./module"
  depends_on           = [module.subnet]
  resource_group_id    = module.resource_group.id
  region               = var.region
  ibmcloud_api_key     = var.ibmcloud_api_key
  vpc_name             = module.vpc.name
  vpc_subnet_count     = module.subnets.count
  vpc_subnets          = module.subnets.subnets
  ssh_key_id           = module.vpcssh.id
  ssh_private_key      = module.vpcssh.private_key
  base_security_group  = module.vpc.base_security_group
}
