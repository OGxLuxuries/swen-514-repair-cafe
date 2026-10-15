variable "name_prefix" {
  description = "Resource naming prefix, such as repair-cafe-dev."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name_prefix) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name_prefix))
    error_message = "Use 2-30 lowercase letters, digits, or hyphens; start with a letter and end with a letter or digit."
  }
}

variable "allowed_origins" {
  description = "Frontend origins allowed to make browser requests, including scheme and optional port but no path."
  type        = list(string)
  nullable    = false

  validation {
    condition = length(var.allowed_origins) > 0 && alltrue([
      for origin in var.allowed_origins : can(regex("^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$", origin))
    ])
    error_message = "Provide at least one explicit HTTP or HTTPS origin without wildcards, paths, or trailing slashes."
  }
}
