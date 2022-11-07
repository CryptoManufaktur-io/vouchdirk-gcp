project_id = "cryptomanufaktur"
regions = {
  us-west1 = { cidr = "10.128.0.0/20" }
  us-central1 = { cidr = "10.138.0.0/20" }
  us-east1 = { cidr = "10.148.0.0/20" }
}

# Compute configuration
compute_size = "e2-micro"
default_tags = ["ssh", "http"]
compute = {
  dirk1 = { region = "us-west1", zone = "b", extra_tags = ["web"] }
  dirk2 = { region = "us-central1", zone = "a", extra_tags = [] }
}

# GKE configuration
gke = {
  lido = { region = "us-east1" }
}
