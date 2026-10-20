terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

# Looks harmless: a project ID and a region, no credentials.
provider "google" {
  project = "jaylabs-lab003-demo"
  region  = "europe-west1"
}

resource "google_storage_bucket" "this" {
  name     = "jaylabs-lab003-naive-bucket"
  location = "EU"
}
