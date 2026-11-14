resource "google_project_service" "this" {
  for_each = toset(var.apis)

  project = var.project_id
  service = each.value

  # Выключение API при destroy ломает всё, что от него зависит
  disable_on_destroy = false
}
