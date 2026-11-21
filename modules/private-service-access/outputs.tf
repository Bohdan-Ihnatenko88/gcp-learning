output "range_name" {
  value = google_compute_global_address.this.name
}

output "range_cidr" {
  value = "${google_compute_global_address.this.address}/${google_compute_global_address.this.prefix_length}"
}

output "peering" {
  description = "Name of the VPC peering to servicenetworking"
  value       = google_service_networking_connection.this.peering
}
