
variable "resource_group_name" {
  type        = string
  default     = "sivasaivm-rg-lab"
  description = "Name of Resource Group in which to provision the VSI. "
}

variable "region" {
  type        = string
  description = "Region.  Must be same Region as the VPC"
}

variable "zone" {
   type        = string
   default     = ""
   description = "Zone in which to provision the VSI.  Must be in the same Region as the VPC."
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key used to provision the IBM Cloud resources"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC into which to provision the VSI.  A subnet will also be created."
}

variable "name_prefix" {
  type        = string
  default     = ""
  description = "Prefix used to name all resources."
}

variable "ssh_key_id" {
   type        = string
   description = "ID of SSH Key already provisioned in the region.  This will be used to access the VSI."
}

variable "ssh_private_key" {
  type        = string
  description = "Location of file with private ssh key.  This is used to remote-exec to the VSI after it is created, and install the SCC Collector"
}

variable "scc_registration_key" {
  type        = string
  description = "SCC Registration Key."
}
