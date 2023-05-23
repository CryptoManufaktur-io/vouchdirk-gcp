resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }

  # Enabling Autopilot for this cluster
  enable_autopilot = true

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.authorized_network
    }
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
# This is mandatory for AutoPilot 1.25
      enabled = true
    }
  }
}
