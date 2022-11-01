#instance
variable "project" {
        description = "name of project you are using"
    }
variable "compute_name" {
        description = "name of instance"
    }
variable "compute_size" {
        description = "size of instance"
    }
variable "compute_image" {
        description = "type of image for instance"
    }
variable "region_name" {
        description = "region instance is deployed in"
    }

#vpc
variable "vpc_name" {
        description = "vpc_name"
    }

#subnetwork
variable "private_subnet_4" {
        description = "private_subnet"
    }
variable "public_subnet_4" {
        description = "public_subnet"
    }
variable "public_subnetwork" {
        description = "public subnetwork name"
    }
variable "private_subnetwork" {
        description = "private subnetwork name"
    }