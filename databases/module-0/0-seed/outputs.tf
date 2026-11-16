# project_id is passed to 1-bootstrap (variable project)

output "project_id" {
  value = google_project.this.project_id
}

output "project_number" {
  value = google_project.this.number
}
