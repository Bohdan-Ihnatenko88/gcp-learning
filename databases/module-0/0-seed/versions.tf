terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9"
    }
  }
}

# Project creation and API enablement run as the caller (admin, ADC)
provider "google" {
  region = var.region
}

# The Billing Budget API needs a quota project to bill the API calls to.
# That is the new project, hence a separate alias with user_project_override.
provider "google" {
  alias                 = "billing"
  user_project_override = true
  billing_project       = var.project_id
}
