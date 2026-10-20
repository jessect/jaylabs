terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  # A fake token: the provider never looks for real credentials.
  # It must be "owner": the Firestore emulator rejects any other string as an invalid JWT.
  access_token = "owner"

  # Every service the lab uses points at a local emulator (REST endpoints).
  storage_custom_endpoint   = var.endpoints.storage
  pubsub_custom_endpoint    = var.endpoints.pubsub
  firestore_custom_endpoint = var.endpoints.firestore
  spanner_custom_endpoint   = var.endpoints.spanner

  # Bigtable is the exception: the provider talks to it over gRPC, and
  # bigtable_custom_endpoint only takes a REST URL. Set BIGTABLE_EMULATOR_HOST instead
  # (source scripts/emulators.env).
}
