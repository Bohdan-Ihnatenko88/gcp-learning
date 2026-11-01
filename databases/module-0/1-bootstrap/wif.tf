# Workload Identity Federation: GitHub Actions входит в GCP без ключей.
# GitHub выдаёт джобе OIDC-токен (repo, ref, workflow), GCP STS его проверяет
# и выдаёт временный токен нужного SA.

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    # repo + ветка в одном атрибуте, чтобы выдать apply только основной ветке
    "attribute.repo_ref" = "assertion.repository + '@' + assertion.ref"
  }

  # Токены из других репозиториев отбрасываются ещё до проверки IAM
  attribute_condition = "assertion.repository == '${var.repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  wif_pool = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}"
}

# plan — любой ref репозитория (PR из веток)
resource "google_service_account_iam_member" "plan_wif" {
  service_account_id = google_service_account.plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.wif_pool}/attribute.repository/${var.repo}"
}

# apply — только основная ветка
resource "google_service_account_iam_member" "apply_wif" {
  service_account_id = google_service_account.apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.wif_pool}/attribute.repo_ref/${var.repo}@refs/heads/${var.apply_branch}"
}
