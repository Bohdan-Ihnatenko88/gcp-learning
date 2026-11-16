# Stage 0: project, billing link, budget.
# Run by an admin with their own account. Everything else is in 1-bootstrap.

resource "google_project" "this" {
  project_id      = var.project_id
  name            = var.project_name
  billing_account = var.billing_account
  labels          = var.labels

  # Parent: a folder or the organization root. Changing the parent moves the
  # project instead of recreating it
  org_id    = var.folder_id == null ? var.org_id : null
  folder_id = var.folder_id

  # No default VPC with open firewall rules: we create the network ourselves
  auto_create_network = false

  # Protects the whole project from an accidental terraform destroy
  deletion_policy = "PREVENT"
}

resource "google_project_service" "seed" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
  ])

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_billing_budget" "this" {
  provider = google.billing

  billing_account = var.billing_account
  display_name    = "${var.project_id} monthly"

  budget_filter {
    projects = ["projects/${google_project.this.number}"]

    # Count the full cost without credits: otherwise on the free trial
    # spend is close to zero and alerts never fire
    credit_types_treatment = "EXCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget_thresholds
    content {
      threshold_percent = threshold_rules.value
    }
  }

  # Forecast rule: email if the month is expected to exceed the budget
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  # Emails go to billing account admins (you, by default)

  depends_on = [google_project_service.seed]
}
