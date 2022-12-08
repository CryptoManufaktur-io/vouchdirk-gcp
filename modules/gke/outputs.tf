output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  # value = data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

# output "access_token" {
#   # value = data.google_client_config.current.access_token
#   value = data.google_client_config.default.access_token
# }
