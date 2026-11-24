variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "service_account_email" {
  description = "VM identity: created in bootstrap together with its project roles"
  type        = string
}

variable "cloudsql_connection_name" {
  description = "project:region:instance the Auth Proxy connects to"
  type        = string
}

variable "postgres_client_version" {
  description = "psql major version, same as the server"
  type        = string
  default     = "17"
}

variable "proxy_version" {
  description = "Cloud SQL Auth Proxy release"
  type        = string
  default     = "v2.27.0"
}

variable "proxy_sha256" {
  description = "sha256 of cloud-sql-proxy.linux.amd64 for proxy_version, from the GitHub release notes"
  type        = string
  default     = "39ed2abcaa073c3b4714585e36a904e2b1d92218c5e07c18224fb73ef4bedde5"
}

variable "labels" {
  type    = map(string)
  default = {}
}
