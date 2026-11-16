resource "google_project_service" "this" {
  for_each = toset(var.apis)

  project = var.project_id
  service = each.value

  # Disabling an API on destroy breaks everything that depends on it
  disable_on_destroy = false
}
