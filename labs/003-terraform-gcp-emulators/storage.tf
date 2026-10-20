resource "google_storage_bucket" "assets" {
  name = "${var.prefix}-assets"

  # fake-gcs-server ignores the location you send and always answers with its own
  # (-location flag, default US-CENTRAL1). Anything else = replaced on every apply.
  location = "US-CENTRAL1"

  # The bucket holds an object: let destroy empty it first.
  force_destroy = true

  versioning {
    enabled = true
  }

  # No labels here: fake-gcs-server drops bucket labels, so they would show up
  # as "1 to change" on every plan. Real GCS keeps them.
}

resource "google_storage_bucket_object" "app_config" {
  bucket       = google_storage_bucket.assets.name
  name         = "config/app.json"
  content_type = "application/json"
  content = jsonencode({
    env      = "local"
    topic    = google_pubsub_topic.orders.name
    database = google_spanner_database.orders.name
  })
}
