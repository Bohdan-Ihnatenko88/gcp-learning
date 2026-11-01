# Стадия 0: проект, привязка billing, бюджет.
# Запускает админ под личным аккаунтом. Остальное — в 1-bootstrap.

resource "google_project" "this" {
  project_id      = var.project_id
  name            = var.project_name
  billing_account = var.billing_account
  labels          = var.labels

  # Родитель: папка или корень организации. Смена родителя переносит проект,
  # а не пересоздаёт его
  org_id    = var.folder_id == null ? var.org_id : null
  folder_id = var.folder_id

  # Без default VPC с открытыми firewall-правилами: сеть создаём сами
  auto_create_network = false

  # Защита от случайного terraform destroy всего проекта
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

    # Считаем полную стоимость, без вычета кредитов: иначе на free trial
    # траты почти нулевые и алерты не срабатывают
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

  # Отдельно — прогноз: письмо придёт, если к концу месяца ожидается превышение
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  # Письма получают админы billing-аккаунта (по умолчанию — вы)

  depends_on = [google_project_service.seed]
}
