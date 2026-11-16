# Terraform linter: catches errors before plan, without GCP access.
# Run: mise run lint (CI does the same in lint.yml)

config {
  # Also lint local modules called from the code
  call_module_type = "local"
}

# Generic terraform rules: versions, variable types, unused declarations
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# GCP rules: unknown machine types, regions, invalid field values
plugin "google" {
  enabled = true
  version = "0.41.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}
