resource "google_compute_address" "ip_address" {
  name = "${var.compute_name}-ip"
  region = var.region

  lifecycle {
    ignore_changes = [
      name
    ]
  }
}

resource "google_compute_instance" "default" {
  name         = var.compute_name
  machine_type = var.compute_size
  zone         = var.zone

  tags = var.tags

  boot_disk {
    initialize_params {
      image = var.compute_image
      type  = "pd-ssd"
      size  = 20
    }
  }

  network_interface {
    network = var.network
    subnetwork = var.subnetwork
    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key)}"
    startup-script = var.metadata_startup_script
  }

  lifecycle {
    ignore_changes = [
      name,
      boot_disk[0].initialize_params[0].image
    ]
  }
}
