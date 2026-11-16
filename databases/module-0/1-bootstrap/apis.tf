resource "google_project_service" "apis" {
  for_each = toset(concat(
    [
      "cloudresourcemanager.googleapis.com",
      "serviceusage.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com", # impersonation: exchanges a token for an SA token
      "sts.googleapis.com",            # WIF: exchanges the GitHub OIDC token
      "storage.googleapis.com",
    ],
    var.enforce_no_sa_keys ? ["orgpolicy.googleapis.com"] : [],
  ))

  service            = each.value
  disable_on_destroy = false
}
