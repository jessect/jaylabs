# Step 4: override_during = plan, but only email + member are set. Then apply.
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

  mock_resource "google_service_account" {
    override_during = plan
    defaults = {
      email  = "dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
      member = "serviceAccount:dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    }
  }
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "dev_apply" {
  command = apply
}
