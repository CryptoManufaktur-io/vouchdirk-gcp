terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.3.0"
    }
  }
  
   backend "gcs" {}

}

provider "google" {
  # Configuration options
  project = var.project_id
}
