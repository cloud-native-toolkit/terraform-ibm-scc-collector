variable "ibmcloud_api_key" {
   default = ""
}

variable "region" {
   default = "us-south"
   description = "Region.  Must be same Region as the VPC"
}

variable "zone" {
   default = "us-south-1"
   description = "Zone in which to provision the VSI.  Must be in the same Region as the VPC."
}

variable "resource_group_id" {
   default = ""
   description = "ID of Resource Group in which to provision the VSI. "
}

variable "vpc_id" {
   default = ""
   description = "ID of VPC into which to provision the VSI.  A subnet will also be created."
}

variable "basename" {
   default = ""
   description = "Prefix used to name all resources."
}

variable "ssh_key_id" {
   type    = list(string)
   default = [""]
   description = "ID of SSH Key already provisioned in the region.  This will be used to access the VSI."
}

variable "ssh_private_key_file" {
  default = "~/.ssh/"
  description = "Location of file with private ssh key.  This is used to remote-exec to the VSI after it is created, and install the SCC Collector"
}

variable "scc_registration_key" {
  default = ""
  description = "SCC Registration Key."
}
