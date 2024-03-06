variable "compute" {
  description = "compute instances"
  type        = map(any)
}

variable "gke" {
  description = "gke clusters"
  type        = map(any)
}

variable "compute_size" {
  description = "Compute Instance size"
  type        = string
}

variable "compute_image" {
  description = "Compute Instance image"
  type        = string
}

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "vouch_tag" {
  description = "Vouch docker image tag"
  type        = string
}

variable "vouch_mem" {
  description = "Vouch max memory"
  type        = string
}

variable "regions" {
  description = "All regions used"
  type        = map(any)
}

variable "default_tags" {
  description = "Default tags when not provided"
  type        = list(string)
}

variable "hostname_prefix" {
  description = "Hostname prefix for VMs"
  type        = string
}

variable "ssh_user" {
  description = "SSH Username"
  type        = string
}

variable "ssh_pub_key" {
  description = "SSH Public Key"
  type        = string
}

variable "ssh_private_key" {
  description = "SSH Private Key"
  type        = string
}

variable "ssh_extra_args" {
  description = "SSH Command extra arguments. E.g: -J for jumphost"
  type        = string
}

variable "acme_email" {
  type = string
}

variable "cf_api_token" {
  type        = string
}

variable "cf_domain" {
  type        = string
}

variable "mev_subdomain" {
  type = string
}

variable "ssh_in_addresses" {
  type = list(string)
}

variable "vouch_https_in_addresses" {
  type        = list(string)
}

variable "exiter_https_in_addresses" {
  type        = list(string)
}
