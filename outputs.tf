output "vsi_private_ips" {
  value = module.scc_vsi.private_ips
}

output "vsi_floating_ips" {
  value = module.scc_vsi.public_ips
}

output "vsi_security_group_id" {
  value = module.scc_vsi.security_group_id
}
