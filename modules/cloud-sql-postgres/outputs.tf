output "instance_name" {
  value = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "project:region:instance, for the Cloud SQL Auth Proxy and connectors"
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip" {
  value = google_sql_database_instance.this.private_ip_address
}

output "admin_password_secret" {
  description = "Secret Manager secret with the postgres password"
  value       = google_secret_manager_secret.admin_password.id
}
