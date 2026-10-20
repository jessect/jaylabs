resource "google_service_account" "app" {
  account_id   = "${var.environment}-app"
  display_name = "Lab 003 app (${var.environment})"

  lifecycle {
    # Catches a provider pointed at the wrong project
    postcondition {
      condition     = endswith(self.email, "@${var.project_id}.iam.gserviceaccount.com")
      error_message = "Service account was created outside project ${var.project_id}: ${self.email}"
    }
  }
}

resource "google_project_iam_member" "app" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = google_service_account.app.member
}
