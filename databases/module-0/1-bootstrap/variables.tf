variable "project" {
  description = "ID GCP-проекта"
  type        = string
}

variable "region" {
  description = "Регион для бакета и ресурсов по умолчанию"
  type        = string
  default     = "europe-west2"
}

variable "repo" {
  description = "GitHub-репозиторий, которому разрешён вход в GCP: owner/name"
  type        = string
}

variable "apply_environment" {
  description = "GitHub environment, джобам которого выдаётся terraform-apply. Имя — точно как в Settings → Environments"
  type        = string
  default     = "Production"
}

variable "plan_impersonators" {
  description = "Кто может действовать от имени terraform-plan: user:… / group:…"
  type        = list(string)
  default     = []
}

variable "apply_impersonators" {
  description = "Кто может действовать от имени terraform-apply. В проде — группа админов"
  type        = list(string)
  default     = []
}

variable "plan_roles" {
  description = "Роли terraform-plan на проект: только чтение"
  type        = list(string)
  default = [
    "roles/viewer",
    "roles/iam.securityReviewer", # чтение IAM-политик для plan по IAM-ресурсам
    # Если в стеке есть google_secret_manager_secret_version, plan читает значение —
    # тогда нужен roles/secretmanager.secretAccessor
  ]
}

variable "apply_roles" {
  description = "Роли terraform-apply на проект: только то, что нужно стекам курса"
  type        = list(string)
  default = [
    "roles/serviceusage.serviceUsageAdmin",  # включение API
    "roles/compute.networkAdmin",            # VPC, подсети, firewall, адреса, router, NAT
    "roles/compute.instanceAdmin.v1",        # VM для подключения к базам
    "roles/servicenetworking.networksAdmin", # Private Service Access
    "roles/cloudsql.admin",                  # Cloud SQL
    "roles/alloydb.admin",                   # AlloyDB
    "roles/redis.admin",                     # Memorystore Redis
    "roles/memcache.admin",                  # Memorystore Memcached
    "roles/spanner.admin",                   # Spanner
    "roles/datastore.owner",                 # Firestore
    "roles/secretmanager.admin",             # секреты с паролями баз
    "roles/storage.admin",                   # бакеты
    "roles/iam.serviceAccountAdmin",         # SA для приложений
    "roles/iam.serviceAccountUser",          # привязка SA к VM и сервисам
    # Намеренно нет roles/resourcemanager.projectIamAdmin: с ним SA может выдать
    # себе любые права. Привязки ролей на проект делает bootstrap / админ.
  ]
}

variable "enforce_no_sa_keys" {
  description = "Запретить JSON-ключи SA через Org Policy. Требует организацию"
  type        = bool
  default     = false
}
