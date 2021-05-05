
variable "resource_group_id" {
  type        = string
  description = "Name of Resource Group in which to provision the VSI. "
}

variable "region" {
  type        = string
  description = "Region.  Must be same Region as the VPC"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key used to provision the IBM Cloud resources"
}

variable "vpc_name" {
  type        = string
  description = "Name of VPC into which to provision the VSI"
}

variable "vpc_subnet_count" {
  type        = number
  description = "Number of vpc subnets"
}

variable "vpc_subnets" {
  type        = list(object({
    label = string
    id    = string
    zone  = string
  }))
  description = "List of subnets with labels"
}

variable "ssh_key_id" {
   type        = string
   description = "ID of SSH Key already provisioned in the region.  This will be used to access the VSI."
}

variable "ssh_private_key" {
  type        = string
  description = "The value of the private key that matches the ssh_key_id."
}

variable "flow_log_cos_bucket_name" {
  type        = string
  description = "Cloud Object Storage bucket id for flow logs (optional)"
  default     = ""
}

variable "kms_enabled" {
  type        = bool
  description = "Flag indicating that the volumes should be encrypted using a KMS."
  default     = false
}

variable "kms_key_crn" {
  type        = string
  description = "The crn of the root key in the kms instance. Required if kms_enabled is true"
  default     = null
}
