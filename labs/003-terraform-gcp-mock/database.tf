resource "google_sql_database_instance" "db" {
  count = local.create_database ? 1 : 0

  name             = "${local.name}-pg"
  database_version = "POSTGRES_16"
  region           = local.region

  # Lab default: easy to delete outside prod
  deletion_protection = local.is_prod

  settings {
    tier              = var.db_tier
    edition           = "ENTERPRISE"
    availability_type = local.is_prod ? "REGIONAL" : "ZONAL"
    user_labels       = local.labels

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = local.is_prod
    }

    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ENCRYPTED_ONLY"
    }
  }
}
