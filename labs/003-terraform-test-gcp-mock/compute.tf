data "google_compute_zones" "available" {
  region = local.region
  status = "UP"
}

locals {
  zone = data.google_compute_zones.available.names[0]
}

resource "google_compute_instance" "app" {
  name         = "${local.name}-app"
  machine_type = var.machine_type
  zone         = local.zone
  tags         = ["ssh"]
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  # Private IP only: no access_config block, so no external IP
  network_interface {
    subnetwork = module.network.subnet_self_links["app"]
  }

  service_account {
    email  = google_service_account.app.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  lifecycle {
    precondition {
      condition     = startswith(local.zone, "${local.region}-")
      error_message = "Zone ${local.zone} is not in region ${local.region}."
    }

    precondition {
      condition     = !(local.is_prod && contains(["e2-micro", "e2-small", "e2-medium"], var.machine_type))
      error_message = "Shared-core machine types (${var.machine_type}) are not allowed in prod."
    }
  }
}
