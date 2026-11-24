include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules/apis"
}

inputs = {
  apis = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com", # Private Service Access for databases
    "iap.googleapis.com",               # SSH to VMs without an external IP
  ]
}
