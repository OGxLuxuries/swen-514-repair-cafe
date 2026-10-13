variable "name_prefix" {
  description = "Resource naming prefix, such as repair-cafe-dev."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name_prefix) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix))
    error_message = "Use 2-30 lowercase letters, digits, or hyphens; start with a letter and end with a letter or digit."
  }
}
