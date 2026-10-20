# Integration-style tests: command = apply against the MOCKED provider.
# Nothing is created anywhere; the mock "applies" and invents computed values.
mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "dev_apply" {
  command = apply

  # Mocked in tests/mocks: without it the mock returns a random string here
  assert {
    condition     = can(cidrhost("${output.instance_internal_ip}/32", 0))
    error_message = "instance_internal_ip is not an IP address: ${output.instance_internal_ip}"
  }

  assert {
    condition     = output.database_connection_name == null
    error_message = "dev has no database, so the output must be null."
  }

  assert {
    condition     = alltrue([for m in google_project_iam_member.app : m.member == google_service_account.app.member])
    error_message = "Every IAM binding must target the app service account."
  }

  # random is NOT mocked: it really runs and generates a password
  assert {
    condition     = length(random_password.db.result) == 24
    error_message = "Database password must be 24 characters."
  }

  assert {
    condition     = google_secret_manager_secret_version.db_password.secret_data == random_password.db.result
    error_message = "The secret version must store the generated password."
  }
}

run "prod_apply" {
  command = apply

  variables {
    environment  = "prod"
    machine_type = "e2-standard-2"
  }

  # The mock cannot know Cloud SQL's PROJECT:REGION:INSTANCE format
  override_resource {
    target = google_sql_database_instance.db
    values = {
      connection_name = "jaylabs-lab003-demo:europe-west1:jaylabs-lab003-prod-pg"
    }
  }

  assert {
    condition     = can(regex("^[a-z0-9-]+:[a-z0-9-]+:[a-z0-9-]+$", output.database_connection_name))
    error_message = "database_connection_name must look like PROJECT:REGION:INSTANCE."
  }

  # Runs share one (mocked) state and can read each other's outputs
  assert {
    condition     = output.bucket_name != run.dev_apply.bucket_name
    error_message = "prod and dev must not share a bucket."
  }
}
