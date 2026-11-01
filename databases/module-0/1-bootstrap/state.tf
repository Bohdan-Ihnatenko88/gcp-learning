resource "google_storage_bucket" "tfstate" {
  name                        = "${var.project}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Версии объектов: можно откатить испорченный стейт
  versioning {
    enabled = true
  }

  # Старые версии стейта храним 30 дней
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 30
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.apis]
}

# plan тоже пишет в бакет: GCS-бэкенд создаёт lock-файл
resource "google_storage_bucket_iam_member" "tfstate" {
  for_each = {
    plan  = google_service_account.plan.email
    apply = google_service_account.apply.email
  }

  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${each.value}"
}
