terraform {
   backend "gcs" {
     bucket  = "lido-terraform-state"
     prefix  = "terraform/lido"
   }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.63.0"
    }
  }
}

provider "google" {
  project     = "lido"
  region      = "asia-southeast1-a"
}

module "gke" {
  source           = "../../modules/gke"
  project_id       = "lido-360921"
  region           = "asia-northeast1"
  cluster_name     = "lido" 
  ip_cidr_range    = "10.148.0.0/20"
  bucket_name      = "lido-cloud-storage"
  bucket_location  = "asia"
  storage_class    = "MULTI_REGIONAL"
  ring_name        = "lido-ring"
  ring_location    = "global"
  key_name         =  "vouch-dirk-key"
}