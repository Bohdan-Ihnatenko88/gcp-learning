# Workload Identity Federation: GitHub Actions signs in to GCP without keys.
# GitHub issues the job an OIDC token (repo, ref, workflow), GCP STS verifies it
# and returns a short-lived token for the right SA.

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
  }

  # Tokens from other repositories are rejected before IAM is checked
  attribute_condition = "assertion.repository == '${var.repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  wif_pool    = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}"
  wif_subject = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject"
}

# plan: any ref of the repository (PRs from branches)
resource "google_service_account_iam_member" "plan_wif" {
  service_account_id = google_service_account.plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.wif_pool}/attribute.repository/${var.repo}"
}

# apply: only jobs in the GitHub environment (required reviewers and branch
# restriction live there). Such a job has sub = repo:<owner>/<repo>:environment:<name>;
# any other job, even on main, does not get the apply SA
resource "google_service_account_iam_member" "apply_wif" {
  service_account_id = google_service_account.apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.wif_subject}/repo:${var.repo}:environment:${var.apply_environment}"
}
