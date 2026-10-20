# Step 7: expect a postcondition failure in an APPLY run, with values known at plan.
mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "rejects_service_account_in_wrong_project" {
  command = apply

  override_resource {
    target          = google_service_account.app
    override_during = plan
    values = {
      id              = "projects/someone-else/serviceAccounts/dev-app@someone-else.iam.gserviceaccount.com"
      name            = "projects/someone-else/serviceAccounts/dev-app@someone-else.iam.gserviceaccount.com"
      project         = "someone-else"
      email           = "dev-app@someone-else.iam.gserviceaccount.com"
      member          = "serviceAccount:dev-app@someone-else.iam.gserviceaccount.com"
      unique_id       = "998877665544332211000"
      deletion_policy = "DELETE"
    }
  }

  expect_failures = [google_service_account.app]
}
