# Общий конфиг для всех стеков, кроме databases/module-0 (там админские стадии
# на чистом terraform, CI их не трогает).
#
# Учётные данные здесь не прописаны: провайдер и бэкенд берут их из окружения —
# в CI от google-github-actions/auth, локально через
# GOOGLE_IMPERSONATE_SERVICE_ACCOUNT (см. задачи в mise.toml).

locals {
  project = "gcp-learning-bohdan88"
  region  = "europe-west2"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  project = "${local.project}"
  region  = "${local.region}"
}
EOF
}

remote_state {
  backend = "gcs"

  config = {
    bucket = "${local.project}-tfstate"
    prefix = "${path_relative_to_include()}"

    # Бакет создан и настроен в module-0/1-bootstrap, terragrunt его не трогает
    skip_bucket_creation   = true
    skip_bucket_versioning = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  project_id = local.project
  region     = local.region
}
