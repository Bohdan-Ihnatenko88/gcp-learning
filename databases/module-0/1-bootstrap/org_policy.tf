# Blocks creation of service account JSON keys.
# Org Policy only works for projects inside an organization (Cloud Identity /
# Workspace). Leave false if the org already enforces it or there is no org.

resource "google_org_policy_policy" "no_sa_keys" {
  count = var.enforce_no_sa_keys ? 1 : 0

  name   = "projects/${var.project}/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/${var.project}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }

  depends_on = [google_project_service.apis]
}
