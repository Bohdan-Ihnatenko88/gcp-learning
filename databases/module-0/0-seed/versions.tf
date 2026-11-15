terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9"
    }
  }
}

# Создание проекта и включение API — от имени того, кто запускает (админ, ADC)
provider "google" {
  region = var.region
}

# Billing Budget API требует проект, на который «записываются» вызовы API.
# Им становится новый проект — поэтому отдельный alias с user_project_override.
provider "google" {
  alias                 = "billing"
  user_project_override = true
  billing_project       = var.project_id
}
