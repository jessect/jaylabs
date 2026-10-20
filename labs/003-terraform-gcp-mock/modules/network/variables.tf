variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr = string
  }))

  validation {
    condition     = alltrue([for s in values(var.subnets) : can(cidrhost(s.cidr, 0))])
    error_message = "Every subnet cidr must be a valid IPv4 CIDR block, e.g. 10.30.1.0/24."
  }
}

variable "ssh_source_ranges" {
  type = list(string)

  validation {
    condition     = !contains(var.ssh_source_ranges, "0.0.0.0/0")
    error_message = "SSH from 0.0.0.0/0 is not allowed. Use the IAP range 35.235.240.0/20."
  }
}
