variable "project_id" {
  type = string
}

variable "network_id" {
  description = "VPC to peer with Google services (projects/<p>/global/networks/<name>)"
  type        = string
}

variable "range_name" {
  description = "Name of the reserved internal range"
  type        = string
}

variable "range_address" {
  description = "First address of the range. Set it explicitly so it never overlaps subnets"
  type        = string
}

variable "range_prefix_length" {
  description = "Range size. /20 leaves room for several database instances"
  type        = number
  default     = 20
}
