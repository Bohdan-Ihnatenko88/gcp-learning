# State lives in the bucket created by 1-bootstrap (migrated with
# `terraform init -migrate-state` after the first bootstrap apply).

terraform {
  backend "gcs" {
    bucket = "gcp-learning-bohdan88-tfstate"
    prefix = "0-seed"
  }
}
