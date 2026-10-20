variable "project" {
  description = "Short project name, used in every resource name."
  type        = string
  default     = "jaylabs"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,11}$", var.project))
    error_message = "project must be 3-12 lowercase letters or digits and start with a letter (it ends up in the storage account name)."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "address_space" {
  description = "Address space of the virtual network."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.address_space))
    error_message = "address_space must be a valid IPv4 CIDR block, for example 10.20.0.0/16."
  }
}

variable "allowed_https_cidrs" {
  description = "Source CIDR blocks allowed to reach port 443."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_https_cidrs) > 0 && alltrue([for c in var.allowed_https_cidrs : can(cidrnetmask(c))])
    error_message = "allowed_https_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "app_service_sku" {
  description = "App Service plan SKU."
  type        = string
  default     = "B1"

  validation {
    condition     = contains(["B1", "B2", "S1", "P0v3", "P1v3"], var.app_service_sku)
    error_message = "app_service_sku must be one of: B1, B2, S1, P0v3, P1v3."
  }
}

variable "tags" {
  description = "Extra tags. The mandatory tags (project, environment, managed_by) always win."
  type        = map(string)
  default     = {}
}
