resource "google_storage_bucket" "tfstate" {
  name                        = "${var.project}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Object versioning: a broken state can be rolled back
  versioning {
    enabled = true
  }

  # Keep old state versions for 30 days
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

# plan also writes to the bucket: the GCS backend creates a lock file
resource "google_storage_bucket_iam_member" "tfstate" {
  for_each = {
    plan  = google_service_account.plan.email
    apply = google_service_account.apply.email
  }

  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${each.value}"
}
