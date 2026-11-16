variable "project_id" {
  description = "New project ID: 6-30 chars, globally unique, cannot be changed later"
  type        = string
}

variable "project_name" {
  description = "Human-readable project name"
  type        = string
  default     = "gcp-learning"
}

variable "org_id" {
  description = "Organization ID (gcloud organizations list). The project is created there unless folder_id is set"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Folder ID inside the organization. If set, the project is created there instead of the org root"
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID: XXXXXX-XXXXXX-XXXXXX (gcloud billing accounts list)"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
  default     = "europe-west2"
}

variable "budget_amount" {
  description = "Monthly budget in the billing account currency"
  type        = number
  default     = 100
}

variable "budget_currency" {
  description = "Budget currency. null means the billing account currency; if set, it must match it"
  type        = string
  default     = null
}

variable "budget_thresholds" {
  description = "Actual spend thresholds (fraction of budget) that trigger an email"
  type        = list(number)
  default     = [0.5, 0.9, 1.0]
}

variable "labels" {
  description = "Project labels"
  type        = map(string)
  default = {
    env        = "learning"
    managed-by = "terraform"
  }
}
