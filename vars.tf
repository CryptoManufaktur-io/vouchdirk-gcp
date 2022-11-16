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

variable "project_id" {
  description = "Project ID"
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