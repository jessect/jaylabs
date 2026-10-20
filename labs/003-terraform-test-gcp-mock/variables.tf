variable "project_id" {
  type        = string
  description = "GCP project ID. Never applied in this lab: tests use a mocked provider."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 characters: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "region" {
  type    = string
  default = "europe-west1"

  validation {
    condition     = contains(["europe-west1", "europe-west4", "us-central1", "us-east1"], var.region)
    error_message = "region must be one of: europe-west1, europe-west4, us-central1, us-east1."
  }
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "name_prefix" {
  type    = string
  default = "jaylabs-lab003"
}

variable "machine_type" {
  type    = string
  default = "e2-micro"

  validation {
    condition     = can(regex("^(e2|n2|n2d|c3)-", var.machine_type))
    error_message = "machine_type must be an e2, n2, n2d or c3 machine type."
  }
}

variable "subnets" {
  type = map(object({
    cidr = string
  }))
  default = {
    app  = { cidr = "10.30.1.0/24" }
    data = { cidr = "10.30.2.0/24" }
  }
}

variable "ssh_source_ranges" {
  type        = list(string)
  description = "Who may SSH to instances tagged `ssh`. Default: Google IAP TCP forwarding range."
  default     = ["35.235.240.0/20"]
}

variable "enable_database" {
  type        = bool
  description = "Create a Cloud SQL instance outside prod (prod always gets one)."
  default     = false
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}
