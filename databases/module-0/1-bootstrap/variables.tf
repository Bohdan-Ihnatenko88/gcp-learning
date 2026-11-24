variable "project" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region for the state bucket and default resources"
  type        = string
  default     = "europe-west2"
}

variable "repo" {
  description = "GitHub repository allowed to sign in to GCP: owner/name"
  type        = string
}

variable "apply_environment" {
  description = "GitHub environment whose jobs get terraform-apply. Name exactly as in Settings -> Environments"
  type        = string
  default     = "Production"
}

variable "plan_impersonators" {
  description = "Who can impersonate terraform-plan: user:... / group:..."
  type        = list(string)
  default     = []
}

variable "apply_impersonators" {
  description = "Who can impersonate terraform-apply. In production, an admin group"
  type        = list(string)
  default     = []
}

variable "plan_roles" {
  description = "terraform-plan project roles: read-only"
  type        = list(string)
  default = [
    "roles/viewer",
    "roles/iam.securityReviewer", # read IAM policies to plan IAM resources
    # If a stack has google_secret_manager_secret_version, plan reads the value,
    # so roles/secretmanager.secretAccessor is needed
  ]
}

variable "apply_roles" {
  description = "terraform-apply project roles: only what the course stacks need"
  type        = list(string)
  default = [
    "roles/serviceusage.serviceUsageAdmin",  # enable APIs
    "roles/compute.networkAdmin",            # VPC, subnets, firewall, addresses, router, NAT
    "roles/compute.instanceAdmin.v1",        # VMs to connect to databases
    "roles/servicenetworking.networksAdmin", # Private Service Access
    "roles/cloudsql.admin",                  # Cloud SQL
    "roles/alloydb.admin",                   # AlloyDB
    "roles/redis.admin",                     # Memorystore Redis
    "roles/memcache.admin",                  # Memorystore Memcached
    "roles/spanner.admin",                   # Spanner
    "roles/datastore.owner",                 # Firestore
    "roles/secretmanager.admin",             # secrets with database passwords
    "roles/storage.admin",                   # buckets
    "roles/iam.serviceAccountAdmin",         # SAs for applications
    "roles/iam.serviceAccountUser",          # attach SAs to VMs and services
    # No roles/resourcemanager.projectIamAdmin on purpose: with it the SA could grant
    # itself any role. Project role bindings are managed by bootstrap / an admin.
  ]
}

variable "enforce_no_sa_keys" {
  description = "Block SA JSON keys via Org Policy. Requires an organization"
  type        = bool
  default     = false
}

variable "db_operators" {
  description = "Who can SSH to the database bastion through IAP: user:... / group:... In production, a group"
  type        = list(string)
  default     = []
}
