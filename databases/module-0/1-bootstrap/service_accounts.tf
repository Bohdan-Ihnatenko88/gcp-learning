# Two Terraform service accounts, used by CI (via WIF) and by people
# (via impersonation), so permissions are the same locally and in CI.
#   terraform-plan  - read-only, for plan on any PR
#   terraform-apply - changes; only Production environment jobs or admins

resource "google_service_account" "plan" {
  account_id   = "terraform-plan"
  display_name = "Terraform plan (read-only)"

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "apply" {
  account_id   = "terraform-apply"
  display_name = "Terraform apply"

  depends_on = [google_project_service.apis]
}

# --- Project roles ------------------------------------------------------

resource "google_project_iam_member" "plan" {
  for_each = toset(var.plan_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.plan.email}"
}

resource "google_project_iam_member" "apply" {
  for_each = toset(var.apply_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.apply.email}"
}

# --- Impersonation for people -----------------------------------------
# A person signs in to gcloud with their own account and Terraform exchanges
# that token for a one-hour SA token. The person has no direct project roles.

resource "google_service_account_iam_member" "plan_impersonators" {
  for_each = toset(var.plan_impersonators)

  service_account_id = google_service_account.plan.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
}

resource "google_service_account_iam_member" "apply_impersonators" {
  for_each = toset(var.apply_impersonators)

  service_account_id = google_service_account.apply.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
}
