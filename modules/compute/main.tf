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

#compute
resource "google_compute_instance" "default" { 
  name         = var.compute_name
  machine_type = var.compute_size
  zone         = var.compute_zone
  project      = var.project_id
  # tags         = ["allow-http"]


  boot_disk {
    initialize_params {
      image = var.compute_image
    }
  }

  network_interface {
    network = var.vpc_name

    access_config {
      // Ephemeral public IP
    }
  }
}


