resource "google_compute_network" "this" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name                     = "${var.name}-${each.key}"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = each.value.cidr
  private_ip_google_access = true
}

# East-west traffic between the subnets of this VPC only
resource "google_compute_firewall" "allow_internal" {
  name          = "${var.name}-allow-internal"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = [for s in values(var.subnets) : s.cidr]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name          = "${var.name}-allow-ssh"
  network       = google_compute_network.this.name
  direction     = "INGRESS"
  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
