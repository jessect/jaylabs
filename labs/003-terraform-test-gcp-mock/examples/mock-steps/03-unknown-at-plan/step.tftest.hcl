# Step 3: both data sources mocked. Now assert a COMPUTED value in a plan run.
mock_provider "google" {
  mock_data "google_client_config" {
    defaults = {
      project = "jaylabs-lab003-demo"
      region  = "europe-west1"
    }
  }

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
    condition     = google_service_account.app.email == "dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    error_message = "Unexpected service account email."
  }
}
