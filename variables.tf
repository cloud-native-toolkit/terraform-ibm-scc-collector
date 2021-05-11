
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

variable "image_name" {
  type        = string
  description = "The name of the image that will be used in the Virtual Server instance"
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-2"
}

variable "init_script" {
  type        = string
  description = "The script used to initialize the Virtual Server instance. If not provided the default script will be used."
  default     = ""
}

variable "base_security_group" {
  type        = string
  description = "The id of the base security group to use for the VSI instance. If not provided the default VPC security group will be used."
  default     = null
}
