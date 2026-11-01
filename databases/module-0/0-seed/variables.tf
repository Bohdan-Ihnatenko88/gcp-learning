variable "project_id" {
  description = "ID нового проекта: 6–30 символов, глобально уникальный, потом не меняется"
  type        = string
}

variable "project_name" {
  description = "Человекочитаемое имя проекта"
  type        = string
  default     = "gcp-learning"
}

variable "org_id" {
  description = "ID организации (gcloud organizations list). Проект создаётся в ней, если не задан folder_id"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "ID папки внутри организации. Если задан, проект создаётся в ней вместо корня организации"
  type        = string
  default     = null
}

variable "billing_account" {
  description = "ID billing-аккаунта: XXXXXX-XXXXXX-XXXXXX (gcloud billing accounts list)"
  type        = string
}

variable "region" {
  description = "Регион по умолчанию"
  type        = string
  default     = "europe-west2"
}

variable "budget_amount" {
  description = "Месячный бюджет в валюте billing-аккаунта"
  type        = number
  default     = 100
}

variable "budget_currency" {
  description = "Валюта бюджета. null — валюта billing-аккаунта; если задана, должна с ней совпадать"
  type        = string
  default     = null
}

variable "budget_thresholds" {
  description = "Пороги фактических трат (доля от бюджета), при которых приходит письмо"
  type        = list(number)
  default     = [0.5, 0.9, 1.0]
}

variable "labels" {
  description = "Метки проекта"
  type        = map(string)
  default = {
    env        = "learning"
    managed-by = "terraform"
  }
}
