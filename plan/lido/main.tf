module "gke" {
  source           = "../../modules/gke"
  project_id       = "lido-360921"
  region           = "asia-northeast1"
  cluster_name     = "lido" 
  ip_cidr_range    = "10.148.0.0/20"
  bucket_name      = "lido-cloud-storage"
  bucket_location  = "asia"
  storage_class    = "MULTI_REGIONAL"
  ring_name        = "lido-ring"
  ring_location    = "global"
  key_name         =  "vouch-dirk-key"
}

module "compute" {
  source           = "../../modules/compute"
  project_id       = "lido-360921"
  region           = "asia-northeast1"
  compute_name     = "dirk1"
  compute_size     = "e2-small"
  compute_zone     = "asia-northeast1-a"
  compute_image    = "debian-cloud/debian-10"
  vpc_name         = "dirk1-vpc"
  router_name      = "dirk1-router"
  nat_name         = "dirk1-nat"
  project          = "lido"
}

module "compute2" {
  source           = "../../modules/compute"
  project_id       = "lido-360921"
  region           = "asia-southeast1"
  compute_name     = "dirk2"
  compute_size     = "e2-small"
  compute_zone     = "asia-southeast1-a"
  compute_image    = "debian-cloud/debian-10"
  vpc_name         = "dirk1-vpc"
  router_name      = "dirk1-router"
  nat_name         = "dirk1-nat"
  project          = "lido"
  providers        = {
  google           = google.singapore
  }
}
