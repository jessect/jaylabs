output "network_name" {
  value = google_compute_network.this.name
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "subnet_self_links" {
  value = { for k, s in google_compute_subnetwork.this : k => s.self_link }
}

output "subnet_cidrs" {
  value = { for k, s in google_compute_subnetwork.this : k => s.ip_cidr_range }
}

output "internal_source_ranges" {
  value = google_compute_firewall.allow_internal.source_ranges
}

output "ssh_source_ranges" {
  value = google_compute_firewall.allow_ssh.source_ranges
}
