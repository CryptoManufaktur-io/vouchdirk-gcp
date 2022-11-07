module "compute" {
  source   = "./modules/compute"
  for_each = var.compute

  compute_name  = each.key
  compute_image = "debian-cloud/debian-10"
  compute_size  = var.compute_size
  zone          = "${each.value.region}-${each.value.zone}"
  tags          = concat(var.default_tags, each.value.extra_tags)

  network = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet[each.value.region].name
}

module "gke" {
  source = "./modules/gke"
  for_each = var.gke

  cluster_name = each.key
  region = each.value.region
  network = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet[each.value.region].name
}

output "kubernetes_cluster_names" {
  value = {
    for key, cluster in module.gke : key => { name = cluster.kubernetes_cluster_name, host = cluster.kubernetes_cluster_host }
  }
}
