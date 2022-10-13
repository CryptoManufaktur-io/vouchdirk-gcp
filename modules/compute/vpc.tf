# Main VPC
resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = true
  project                 = var.project_id
}

# Cloud Router
resource "google_compute_router" "router" {
  name    = var.router_name
  network = google_compute_network.main.id
  project = var.project_id

}

# NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

    log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

}

#Firewall Rules
resource "google_compute_firewall" "ssh" {
  name = "allow-ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.main.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}