resource "google_compute_network" "vpc" {
  name                    =  "dirk-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
  project                 = var.project
}
resource "google_compute_firewall" "allow-internal" {
  name                    = "${var.project}-fw-allow-internal"
  network                 = "${google_compute_network.vpc.name}"
  project                 = var.project
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    "${var.private_subnet_1}",
    "${var.private_subnet_1}",
    "${var.public_subnet_2}",
    "${var.public_subnet_2}"
  ]
}
resource "google_compute_firewall" "allow-http" {
  name                    = "${var.project}-fw-allow-http"
  network                 = "${google_compute_network.vpc.name}"
  project                 = var.project
allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = ["http"] 
}
resource "google_compute_firewall" "allow-bastion" {
  name                    = "${var.project}-fw-allow-bastion"
  network                 = "${google_compute_network.vpc.name}"
  project                 = var.project
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh"]
  }