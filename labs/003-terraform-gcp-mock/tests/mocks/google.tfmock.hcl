# Shared mock data for every test file: mock_provider "google" { source = "./tests/mocks" }
# Without these, the mock invents random 8-character strings and empty lists.

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

# Real GCP derives the email from account_id + project. The mock cannot,
# so we give it the value GCP would return, already known at plan time.
# With override_during = plan, set EVERY computed attribute: anything left out
# gets a new random value at apply -> "Provider produced inconsistent final plan".
mock_resource "google_service_account" {
  override_during = plan
  defaults = {
    id              = "projects/jaylabs-lab003-demo/serviceAccounts/dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    name            = "projects/jaylabs-lab003-demo/serviceAccounts/dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    project         = "jaylabs-lab003-demo"
    email           = "dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    member          = "serviceAccount:dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    unique_id       = "112233445566778899001"
    deletion_policy = "DELETE"
  }
}

# Nested blocks are mocked per element: an object, not a list.
mock_resource "google_compute_instance" {
  defaults = {
    network_interface = { network_ip = "10.30.1.2" }
  }
}
