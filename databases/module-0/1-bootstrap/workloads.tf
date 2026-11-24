# Service accounts of workloads that need project roles. Created here, not in
# the stacks: terraform-apply cannot change project IAM (no projectIamAdmin),
# and Cloud SQL roles exist only at project level.

# --- db-bastion: VM for connecting to databases ---------------------------
# Runs the Cloud SQL Auth Proxy and signs in to Postgres as an IAM user.

resource "google_service_account" "db_bastion" {
  account_id   = "db-bastion"
  display_name = "Database bastion VM"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "db_bastion" {
  for_each = toset([
    "roles/cloudsql.client",       # connect through the Auth Proxy
    "roles/cloudsql.instanceUser", # IAM database authentication
    "roles/logging.logWriter",     # VM logs to Cloud Logging
    "roles/monitoring.metricWriter",
  ])

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.db_bastion.email}"
}

# --- People who connect to databases through the bastion ------------------

resource "google_project_iam_member" "db_operators" {
  for_each = {
    for pair in setproduct(var.db_operators, [
      "roles/iap.tunnelResourceAccessor", # SSH through IAP, no external IP
      "roles/compute.osLogin",            # sign in with the Google account, no sudo
      "roles/compute.viewer",             # gcloud compute ssh looks up the VM
    ]) : "${pair[0]} ${pair[1]}" => { member = pair[0], role = pair[1] }
  }

  project = var.project
  role    = each.value.role
  member  = each.value.member
}

# OS Login on a VM with an attached SA also requires actAs on that SA
resource "google_service_account_iam_member" "db_operators_bastion_user" {
  for_each = toset(var.db_operators)

  service_account_id = google_service_account.db_bastion.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}
