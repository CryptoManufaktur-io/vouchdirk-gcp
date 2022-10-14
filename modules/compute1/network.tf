resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.region_name-pub-net}"
  ip_cidr_range = "${var.public_subnet}"
  network       = "${var.network_self_link}"
  region        = "${var.region_name}"
}
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.region_name-pub-net}"
  ip_cidr_range = "${var.private_subnet}"
  network       = "${var.network_self_link}"
  region        = "${var.region_name}"
}