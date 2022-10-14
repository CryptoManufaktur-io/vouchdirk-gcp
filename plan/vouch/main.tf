module "gke" {
  source           = "../../modules/gke"
  project_id       = "lido-360921"
  region           = "asia-northeast1"
  cluster_name     = "lido" 
  ip_cidr_range    = "10.148.0.0/20"
  bucket_name      = "lido-cloud-storage"
  bucket_location  = "asia"
  storage_class    = "MULTI_REGIONAL"
}
