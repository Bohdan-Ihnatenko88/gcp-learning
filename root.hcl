# Shared config for all stacks except databases/module-0 (admin stages in
# plain terraform, not touched by CI).
#
# No credentials here: the provider and backend take them from the environment,
# in CI from google-github-actions/auth, locally via
# GOOGLE_IMPERSONATE_SERVICE_ACCOUNT (see tasks in mise.toml).

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

    # The bucket is created and configured in module-0/1-bootstrap; terragrunt leaves it alone
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
