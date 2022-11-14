variable "compute_name" {
  description = "name of instance"
  type = string
}

variable "compute_size" {
  description = "size of instance"
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

variable "compute_image" {
  description = "type of image for instance"
  type = string
}

variable "zone" {
  description = "zone instance is deployed in"
  type = string
}

variable "tags" {
  description = "Tags for the instance"
  type        = list(string)
}
