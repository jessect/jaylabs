# Step 1: an empty mock. Every computed value is invented: lists are empty.
mock_provider "google" {}

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
