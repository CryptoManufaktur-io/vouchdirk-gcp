resource "google_compute_instance" "default" {
  name         = var.compute_name
  machine_type  = var.compute_size
  #zone         =   "${element(var.var_zones, count.index)}"
  zone          =   "${format("%s","${var.region_name}-b")}"
  tags          = ["ssh","http"]
  project       = var.project
  boot_disk {
    initialize_params {
      image     =  var.compute_image    
    }
  }


network_interface {
    subnetwork = "${google_compute_subnetwork.public_subnet_1.self_link}"
    access_config {
      // Ephemeral IP
    }
  }
}