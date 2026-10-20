# Bad input must be rejected: variable validation, preconditions, postconditions.
mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "rejects_bad_project_id" {
  command = plan

  variables {
    project_id = "My_Project"
  }

  expect_failures = [var.project_id]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}

run "rejects_shared_core_in_prod" {
  command = plan

  variables {
    environment = "prod" # machine_type stays e2-micro
  }

  expect_failures = [google_compute_instance.app]
}

run "rejects_zone_outside_region" {
  command = plan

  # Simulate a lookup that returns zones from another region
  override_data {
    target = data.google_compute_zones.available
    values = {
      names = ["us-central1-a"]
    }
  }

  expect_failures = [google_compute_instance.app]
}

# The email is known at plan (override_during = plan), so the postcondition
# already fails during plan. With command = apply this run would fail.
run "rejects_service_account_in_wrong_project" {
  command = plan

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
