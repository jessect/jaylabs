# What mocks do NOT prove. This run PASSES, and every value below is nonsense:
# there is no e2-banana machine type and no db-banana Cloud SQL tier.
# A mock only knows the provider schema and its static validators.
# Only a real plan/apply against GCP (or a policy tool) would catch these.
mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "mock_accepts_nonsense" {
  command = apply

  variables {
    machine_type    = "e2-banana"
    enable_database = true
    db_tier         = "db-banana"
  }

  assert {
    condition     = google_compute_instance.app.machine_type == "e2-banana"
    error_message = "Unreachable: the mock accepts any machine type."
  }
}
