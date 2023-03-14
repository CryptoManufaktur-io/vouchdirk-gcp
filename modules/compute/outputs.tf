output "ip_address" {
    value = google_compute_address.ip_address
}

output "zone" {
    value = google_compute_instance.default.zone
}

output "name" {
    value = google_compute_instance.default.name
}
