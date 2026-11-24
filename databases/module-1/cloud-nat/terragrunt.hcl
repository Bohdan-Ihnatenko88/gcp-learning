include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules/cloud-nat"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  network_id  = dependency.network.outputs.network_id
  router_name = "learning-router"
  nat_name    = "learning-nat"
}
