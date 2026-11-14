variable "project_id" {
  type = string
}

variable "apis" {
  description = "API, которые включаются в проекте"
  type        = list(string)
}
