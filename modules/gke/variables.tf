variable "cluster_name" {
  description = "Cluster name"
  type = string
}

variable "region" {
  description = "Cluster region"
  type = string
}

variable "network" {
  description = "Network"
  type = string
}

variable "subnetwork" {
  description = "Subnetwork"
  type = string
}

variable "authorized_network" {
  type = string
}
