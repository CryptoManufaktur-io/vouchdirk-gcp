# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnets
resource "google_compute_subnetwork" "subnet" {
  for_each = var.regions

  name          = "${each.key}-subnet"
  region        = each.key
  network       = google_compute_network.vpc.name
  ip_cidr_range = each.value.cidr
}

resource "google_compute_subnetwork" "gke_subnet" {
  for_each =  var.gke

  name          = "gke-${each.key}-subnet"
  region        = each.value.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = each.value.cidr
  private_ip_google_access = true
}
