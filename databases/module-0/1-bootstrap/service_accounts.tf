# Два сервисных аккаунта Terraform. Ими пользуются и CI (через WIF), и люди
# (через impersonation), поэтому права локально и в CI одинаковые.
#   terraform-plan  — только чтение, для plan на любых PR
#   terraform-apply — изменения, только из основной ветки или у админов

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

# --- Роли на проект -----------------------------------------------------

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

# --- Impersonation для людей ------------------------------------------
# Человек логинится в gcloud под своим аккаунтом, а Terraform обменивает его
# токен на часовой токен SA. Прямых прав на проект у человека нет.

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
