resource "google_storage_bucket" "assets" {
  name     = "${var.project_id}-${var.environment}-assets"
  location = upper(local.region)
  labels   = local.labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Throwaway environments can be destroyed with objects inside
  force_destroy = !local.is_prod

  versioning {
    enabled = local.is_prod
  }

  # Non-prod: delete objects after 30 days. prod: keep everything.
  dynamic "lifecycle_rule" {
    for_each = local.is_prod ? [] : [30]

    content {
      condition {
        age = lifecycle_rule.value
      }
      action {
        type = "Delete"
      }
    }
  }
}
