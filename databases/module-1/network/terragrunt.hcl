include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-google-modules/network/google?version=18.3.1"
}

# Только порядок: сначала включаются API
dependencies {
  paths = ["../apis"]
}

inputs = {
  network_name = "learning-vpc"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "learning-europe-west2"
      subnet_ip             = "10.10.0.0/24"
      subnet_region         = "europe-west2"
      subnet_private_access = "true" # доступ к Google API без внешнего IP
    },
  ]
}
