resource "google_compute_subnetwork" "public_subnet_3" {
  name          = var.public_subnetwork
  ip_cidr_range = var.public_subnet_3
  network       = var.vpc_name
  region        = var.region_name
  project       = var.project
}
resource "google_compute_subnetwork" "private_subnet_3" {
  name          = var.private_subnetwork
  ip_cidr_range = var.private_subnet_3
  network       = var.vpc_name
  region        = var.region_name
  project       = var.project
}
