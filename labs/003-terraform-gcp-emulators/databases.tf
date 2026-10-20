# Cloud Spanner: the emulator exposes a single config called "emulator-config".
resource "google_spanner_instance" "main" {
  name         = "${var.prefix}-spanner"
  config       = "emulator-config"
  display_name = "JayLabs Lab 003"
  num_nodes    = 1
}

resource "google_spanner_database" "orders" {
  instance = google_spanner_instance.main.name
  name     = "orders"
  ddl = [
    "CREATE TABLE Orders (OrderId STRING(36) NOT NULL, Item STRING(100), Qty INT64) PRIMARY KEY (OrderId)",
  ]

  # Lab only: the default (true) makes terraform destroy fail.
  deletion_protection = false
}

# Firestore: one seed document in the (default) database.
resource "google_firestore_document" "feature_flags" {
  database    = "(default)"
  collection  = "config"
  document_id = "feature-flags"
  fields = jsonencode({
    new_checkout = { booleanValue = true }
    max_items    = { integerValue = "10" }
  })
}

# Bigtable: the emulator only implements the table API, not instances.
# Any instance name works, so there is no google_bigtable_instance here.
resource "google_bigtable_table" "events" {
  name          = "events"
  instance_name = "${var.prefix}-bt"

  column_family {
    family = "order"
  }

  deletion_protection = "UNPROTECTED"
}
