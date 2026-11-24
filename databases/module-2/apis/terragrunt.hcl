include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules/apis"
}

inputs = {
  apis = [
    "sqladmin.googleapis.com",      # Cloud SQL
    "secretmanager.googleapis.com", # break-glass database passwords
  ]
}
