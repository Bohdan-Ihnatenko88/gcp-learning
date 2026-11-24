output "name" {
  value = google_compute_instance.this.name
}

output "zone" {
  value = google_compute_instance.this.zone
}

output "ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.this.name} --zone ${google_compute_instance.this.zone} --tunnel-through-iap"
}
