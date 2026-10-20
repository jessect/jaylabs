terraform {
  # override_during (used in tests/) needs Terraform 1.11+
  required_version = ">= 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# No credentials here on purpose. `terraform test` replaces this provider with
# `mock_provider "google"`, so no project, no billing account and no login are needed.
provider "google" {
  project = var.project_id
  region  = var.region
}
