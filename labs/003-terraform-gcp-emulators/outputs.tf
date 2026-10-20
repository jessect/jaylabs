output "project_id" {
  value = var.project_id
}

output "bucket_name" {
  value = google_storage_bucket.assets.name
}

output "config_object" {
  value = google_storage_bucket_object.app_config.name
}

output "topic_name" {
  value = google_pubsub_topic.orders.name
}

output "subscription_name" {
  value = google_pubsub_subscription.orders_worker.name
}

output "spanner_instance" {
  value = google_spanner_instance.main.name
}

output "spanner_database" {
  value = google_spanner_database.orders.name
}

output "firestore_document" {
  value = google_firestore_document.feature_flags.path
}

output "bigtable_instance" {
  value = google_bigtable_table.events.instance_name
}

output "bigtable_table" {
  value = google_bigtable_table.events.name
}
