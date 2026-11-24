include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/modules/bastion"
}

dependency "network" {
  config_path = "../../module-1/network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock"
    subnet_id  = "projects/mock/regions/europe-west2/subnetworks/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "cloudsql" {
  config_path = "../cloud-sql-postgres"

  mock_outputs = {
    connection_name = "mock:europe-west2:mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Ordering only: apt goes out through Cloud NAT
dependencies {
  paths = ["../../module-1/cloud-nat"]
}

inputs = {
  name       = "db-bastion"
  zone       = "${include.root.locals.region}-a"
  network_id = dependency.network.outputs.network_id
  subnet_id  = dependency.network.outputs.subnet_id

  # Created in module-0/1-bootstrap (workloads.tf) with its project roles
  service_account_email = "db-bastion@${include.root.locals.project}.iam.gserviceaccount.com"

  cloudsql_connection_name = dependency.cloudsql.outputs.connection_name

  labels = {
    course = "databases"
    module = "module-2"
  }
}
