# Шаг 5 README: после первого apply переименуйте в backend.tf,
# подставьте имя бакета и выполните `terraform init -migrate-state`.

terraform {
  backend "gcs" {
    bucket = "gcp-learning-bohdan88-tfstate"
    prefix = "bootstrap"
  }
}
