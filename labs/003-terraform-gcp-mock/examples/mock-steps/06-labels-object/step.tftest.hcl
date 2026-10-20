# Step 6: compare a map attribute with an object literal.
mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "dev_labels" {
  command = plan

  assert {
    condition     = google_compute_instance.app.labels == { lab = "003", environment = "dev", managed_by = "terraform" }
    error_message = "Instance labels are wrong."
  }
}
