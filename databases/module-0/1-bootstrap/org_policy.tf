# Запрет на создание JSON-ключей сервисных аккаунтов.
# Org Policy работает только для проектов внутри организации (Cloud Identity /
# Workspace). У проекта на личном аккаунте организации нет — тогда оставьте false.

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
