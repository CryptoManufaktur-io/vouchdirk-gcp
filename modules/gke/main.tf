resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

# Enabling Autopilot for this cluster
  enable_autopilot = true

  network    = var.network
  subnetwork = var.subnetwork

  vertical_pod_autoscaling {
    enabled = true
  }
}