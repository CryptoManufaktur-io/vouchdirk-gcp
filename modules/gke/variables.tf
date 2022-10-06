variable "gke_username" {
  default     = ""
  description = "gke username"
}
 
variable "gke_password" {
  default     = ""
  description = "gke password"
}
 
variable "project_id" {
  description = "project_id"
}

variable "region" {
  description = "region"
}

variable "cluster_name" {
  description = "cluster_name"
}

variable "ip_cidr_range" {
  description = "ip_cidr_range"
}

variable "bucket_name" {
  description = "GCS Bucket name. Value should be unique ."
  type        = string
}

variable "bucket_location" {
  type        = string
}

variable "storage_class" {
  type        = string
}

variable "ring_name" {
  type        = string
  description = "KMS key ring name"
}

variable "key_name" {
  type        = string
  description = "KMS key ring name"
}

variable "ring_location" {
  type        = string
  description = "KMS key location"
}

