include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-google-modules/project-factory/google//modules/project_services?version=18.4.0"
}

inputs = {
  activate_apis = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com", # Private Service Access для баз
  ]

  # Выключение API при destroy ломает всё, что от него зависит
  disable_services_on_destroy = false
}
