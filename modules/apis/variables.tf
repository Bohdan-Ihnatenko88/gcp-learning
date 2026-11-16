variable "project_id" {
  type = string
}

variable "apis" {
  description = "APIs to enable in the project"
  type        = list(string)
}
