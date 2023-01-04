output "name" {
  value = google_container_cluster.primary.name
}

output "master_version" {
  value       = google_container_cluster.primary.master_version
}

output "endpoint" {
  sensitive   = true
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  value       = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}
