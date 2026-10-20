resource "google_pubsub_topic" "orders" {
  name = "${var.prefix}-orders"

  labels = {
    lab = "003"
  }
}

resource "google_pubsub_topic" "orders_dlq" {
  name = "${var.prefix}-orders-dlq"
}

resource "google_pubsub_subscription" "orders_worker" {
  name                 = "${var.prefix}-orders-worker"
  topic                = google_pubsub_topic.orders.id
  ack_deadline_seconds = 20

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.orders_dlq.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "300s"
  }
}
