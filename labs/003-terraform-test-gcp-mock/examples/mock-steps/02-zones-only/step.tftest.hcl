# Step 2: zones mocked, but google_client_config still returns a random region.
mock_provider "google" {
  mock_data "google_compute_zones" {
    defaults = {
      names = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
    }
  }
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "dev_defaults" {
  command = plan

  assert {
    condition     = google_storage_bucket.assets.name == "jaylabs-lab003-demo-dev-assets"
    error_message = "Bucket name must be <project>-<env>-assets."
  }
}
