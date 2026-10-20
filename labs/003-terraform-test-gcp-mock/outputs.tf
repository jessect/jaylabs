output "network_name" {
  value = module.network.network_name
}

output "subnet_cidrs" {
  value = module.network.subnet_cidrs
}

output "bucket_name" {
  value = google_storage_bucket.assets.name
}

output "bucket_url" {
  value = google_storage_bucket.assets.url
}

output "service_account_email" {
  value = google_service_account.app.email
}

output "instance_zone" {
  value = google_compute_instance.app.zone
}

output "instance_internal_ip" {
  value = google_compute_instance.app.network_interface[0].network_ip
}

output "secret_id" {
  value = google_secret_manager_secret.db_password.secret_id
}

output "database_connection_name" {
  description = "PROJECT:REGION:INSTANCE, or null when there is no database"
  value       = one(google_sql_database_instance.db[*].connection_name)
}
