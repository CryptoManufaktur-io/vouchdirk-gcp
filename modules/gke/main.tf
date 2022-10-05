# Version
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.63.0"
    }
  }
 
  required_version = "~> 1.2.6"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

# Enabling Autopilot for this cluster
  enable_autopilot = true

  vertical_pod_autoscaling {
    enabled = true
  }
}

# GCS Bucket
resource "google_storage_bucket" "my_bucket" {
location      = var.bucket_location
name          = var.bucket_name
storage_class = var.storage_class 
}

# KMS Key Ring
resource "google_kms_key_ring" "default" {
  name     = var.ring_name
  location = var.ring_location
}

resource "google_kms_crypto_key" "default" {
  name            = var.key_name
  key_ring        = google_kms_key_ring.default.id
  rotation_period = "100000s"

    lifecycle {
    prevent_destroy = true
  }
}

