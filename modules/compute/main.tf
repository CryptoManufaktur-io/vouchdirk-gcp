resource "google_compute_instance" "default" {
  name         = var.compute_name
  machine_type = var.compute_size
  zone         = var.zone

  tags = var.tags

  boot_disk {
    initialize_params {
      image = var.compute_image
    }
  }


  network_interface {
    network = var.network
    subnetwork = var.subnetwork
    access_config {
      // Ephemeral IP
    }
  }
}