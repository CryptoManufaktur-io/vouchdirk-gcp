output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "key_ring" {
  value       = google_kms_key_ring.default.self_link
  description = "GCP Key Ring"
}

output "kms_key" {
  value       = google_kms_crypto_key.default.self_link
  description = "GCP KMS Key"
}

