variable "name_prefix" {
  description = "Resource naming prefix, such as repair-cafe-dev."
  type        = string
  nullable    = false

  validation {
    // prefix must be 2-32 letters, start with a lowercase, end with a lowercase or digit, and only
    // contain digits, lowercase letters, or hyphens
    condition     = length(var.name_prefix) <= 32 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix))
    error_message = "Use 2-32 lowercase letters, digits, or hyphens; start with a letter and end with a letter or digit."
  }
}
