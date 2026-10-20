# Unit tests: plan only, mocked provider, no project, no credentials.
mock_provider "google" {
  source = "./tests/mocks"
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

  assert {
    condition     = google_storage_bucket.assets.location == "EUROPE-WEST1"
    error_message = "Bucket must live in the provider region."
  }

  assert {
    condition     = google_storage_bucket.assets.public_access_prevention == "enforced" && google_storage_bucket.assets.uniform_bucket_level_access
    error_message = "Bucket must block public access and use uniform bucket-level access."
  }

  assert {
    condition     = google_storage_bucket.assets.versioning[0].enabled == false && google_storage_bucket.assets.force_destroy
    error_message = "dev bucket: no versioning, force_destroy on."
  }

  assert {
    # condition is a set block: [0] does not work, one() does
    condition     = one(google_storage_bucket.assets.lifecycle_rule[0].condition).age == 30
    error_message = "dev bucket must delete objects after 30 days."
  }

  assert {
    condition     = length(google_sql_database_instance.db) == 0
    error_message = "dev must not create Cloud SQL unless enable_database = true."
  }

  assert {
    condition     = google_compute_instance.app.zone == "europe-west1-b"
    error_message = "Instance must use the first UP zone of the region."
  }

  assert {
    condition     = length(google_compute_instance.app.network_interface[0].access_config) == 0
    error_message = "Instance must not get an external IP."
  }

  # Computed in real GCP; known at plan only thanks to override_during = plan in the mock
  assert {
    condition     = google_compute_instance.app.service_account[0].email == "dev-app@jaylabs-lab003-demo.iam.gserviceaccount.com"
    error_message = "Instance must run as the app service account."
  }

  assert {
    condition     = keys(google_project_iam_member.app) == ["roles/logging.logWriter", "roles/monitoring.metricWriter"]
    error_message = "The app service account gets exactly logWriter and metricWriter."
  }

  # A { ... } literal is an object, labels is a map: compare with tomap()
  assert {
    condition     = google_compute_instance.app.labels == tomap({ lab = "003", environment = "dev", managed_by = "terraform" })
    error_message = "Instance labels are wrong."
  }
}

run "prod_hardening" {
  command = plan

  variables {
    environment  = "prod"
    machine_type = "e2-standard-2"
  }

  assert {
    condition     = google_storage_bucket.assets.versioning[0].enabled && !google_storage_bucket.assets.force_destroy
    error_message = "prod bucket: versioning on, force_destroy off."
  }

  assert {
    condition     = length(google_storage_bucket.assets.lifecycle_rule) == 0
    error_message = "prod bucket must keep objects (no delete rule)."
  }

  assert {
    condition     = length(google_sql_database_instance.db) == 1
    error_message = "prod always gets a database."
  }

  assert {
    condition     = google_sql_database_instance.db[0].settings[0].availability_type == "REGIONAL"
    error_message = "prod database must be REGIONAL (HA)."
  }

  assert {
    condition     = google_sql_database_instance.db[0].deletion_protection && google_sql_database_instance.db[0].settings[0].backup_configuration[0].point_in_time_recovery_enabled
    error_message = "prod database needs deletion protection and point-in-time recovery."
  }
}

run "staging_database_opt_in" {
  command = plan

  variables {
    environment     = "staging"
    enable_database = true
  }

  assert {
    condition     = google_sql_database_instance.db[0].name == "jaylabs-lab003-staging-pg"
    error_message = "Database name must be <prefix>-<env>-pg."
  }

  assert {
    condition     = google_sql_database_instance.db[0].settings[0].availability_type == "ZONAL" && !google_sql_database_instance.db[0].deletion_protection
    error_message = "Non-prod database: ZONAL and easy to delete."
  }
}

run "subnets_for_each" {
  command = plan

  variables {
    subnets = {
      app  = { cidr = "10.30.1.0/24" }
      data = { cidr = "10.30.2.0/24" }
      jobs = { cidr = "10.30.3.0/24" }
    }
  }

  assert {
    condition     = output.subnet_cidrs == { app = "10.30.1.0/24", data = "10.30.2.0/24", jobs = "10.30.3.0/24" }
    error_message = "One subnet per map entry."
  }
}
