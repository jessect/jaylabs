terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

provider "google" {
  project = "jaylabs-local"
  region  = "us-central1"
}

resource "google_storage_bucket" "this" {
  name     = "jaylabs-lab003-naive-bucket"
  location = "US-CENTRAL1"
}
