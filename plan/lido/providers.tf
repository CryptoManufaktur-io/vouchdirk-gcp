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
  project     = "lido-360921"
  region      = "asia-northeast1"
}

provider "google" {
  project     = "lido-360921"
  region      = "asia-southeast1"
  alias       = "singapore"
}

provider "google" {
  project     = "lido-360921"
  region      = "asia-northeast3"
  alias       = "south-korea"
}