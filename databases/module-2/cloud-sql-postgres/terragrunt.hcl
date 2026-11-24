include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/modules/cloud-sql-postgres"
}

dependency "network" {
  config_path = "../../module-1/network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "psa" {
  config_path = "../../module-1/private-service-access"

  mock_outputs = {
    range_name = "google-managed-services"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Ordering only: Cloud SQL and Secret Manager APIs are enabled first
dependencies {
  paths = ["../apis"]
}

inputs = {
  name               = "learning-pg"
  network_id         = dependency.network.outputs.network_id
  allocated_ip_range = dependency.psa.outputs.range_name

  # Cost trade-off for the free trial, the module defaults are the production values
  # (db-custom-2-7680, REGIONAL). Shared-core tiers have no SLA.
  tier              = "db-f1-micro"
  availability_type = "ZONAL"
  disk_size_gb      = 10

  databases = ["app"]

  # Bastion VM signs in through the Auth Proxy with IAM, no password.
  # The SA and its project roles are created in module-0/1-bootstrap.
  iam_users = ["serviceAccount:db-bastion@${include.root.locals.project}.iam.gserviceaccount.com"]

  labels = {
    course = "databases"
    module = "module-2"
  }
}
