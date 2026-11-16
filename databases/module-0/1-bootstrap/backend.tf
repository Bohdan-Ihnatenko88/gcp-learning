# State lives in the bucket created by this stage (migrated with
# `terraform init -migrate-state` after the first apply).

terraform {
  backend "gcs" {
    bucket = "gcp-learning-bohdan88-tfstate"
    prefix = "bootstrap"
  }
}
