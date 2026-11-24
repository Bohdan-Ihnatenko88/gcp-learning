# The first three values go to GitHub: Settings -> Secrets and variables -> Actions -> Variables

output "GCP_WORKLOAD_IDENTITY_PROVIDER" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "GCP_SA_PLAN" {
  value = google_service_account.plan.email
}

output "GCP_SA_APPLY" {
  value = google_service_account.apply.email
}

output "tfstate_bucket" {
  value = google_storage_bucket.tfstate.name
}

output "db_bastion_sa" {
  value = google_service_account.db_bastion.email
}
