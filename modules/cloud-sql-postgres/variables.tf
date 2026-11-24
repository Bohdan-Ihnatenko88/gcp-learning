variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  description = "Instance name. A deleted name cannot be reused for about a week"
  type        = string
}

variable "database_version" {
  type    = string
  default = "POSTGRES_17"
}

variable "edition" {
  description = "ENTERPRISE or ENTERPRISE_PLUS. Shared-core tiers need ENTERPRISE"
  type        = string
  default     = "ENTERPRISE"
}

variable "tier" {
  description = "Machine type. Production: db-custom-<vCPU>-<MB> or db-perf-optimized-*"
  type        = string
  default     = "db-custom-2-7680"
}

variable "availability_type" {
  description = "REGIONAL = standby in another zone with automatic failover; ZONAL = single zone"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "availability_type must be REGIONAL or ZONAL."
  }
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "disk_autoresize_limit_gb" {
  description = "Upper bound for automatic disk growth, 0 = no limit"
  type        = number
  default     = 100
}

variable "network_id" {
  description = "VPC with a Private Service Access connection"
  type        = string
}

variable "allocated_ip_range" {
  description = "Name of the PSA range to take the IP from"
  type        = string
}

variable "databases" {
  type    = list(string)
  default = []
}

variable "iam_users" {
  description = "IAM principals that get a database user: user:... / serviceAccount:..."
  type        = list(string)
  default     = []
}

variable "database_flags" {
  description = "Extra flags, merged over the module defaults"
  type        = map(string)
  default     = {}
}

variable "backup_retention_count" {
  type    = number
  default = 14
}

variable "admin_password_version" {
  description = "Bump to generate and set a new postgres password"
  type        = number
  default     = 1
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}
