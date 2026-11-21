include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules/private-service-access"
}

dependency "network" {
  config_path = "../network"

  # Lets plan run in a PR before network exists in state
  mock_outputs = {
    network_id = "projects/mock/global/networks/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  network_id = dependency.network.outputs.network_id

  # Subnet is 10.10.0.0/24; databases get a separate, non-overlapping block
  range_name          = "google-managed-services"
  range_address       = "10.20.0.0"
  range_prefix_length = 20
}
