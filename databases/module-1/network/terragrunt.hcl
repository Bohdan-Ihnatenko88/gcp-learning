include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules/network"
}

# Ordering only: APIs are enabled first
dependencies {
  paths = ["../apis"]
}

inputs = {
  network_name = "learning-vpc"
  subnet_name  = "learning-europe-west2"
  subnet_cidr  = "10.10.0.0/24"
}
