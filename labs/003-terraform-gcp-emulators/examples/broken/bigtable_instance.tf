# Expected to fail: the Bigtable emulator has no instance API.
# Reproduce from the lab folder:
#   cp examples/broken/bigtable_instance.tf . && terraform apply -auto-approve
#   rm bigtable_instance.tf
resource "google_bigtable_instance" "main" {
  name                = "jaylabs-lab003-bt"
  deletion_protection = false

  cluster {
    cluster_id   = "jaylabs-lab003-bt-c1"
    zone         = "us-central1-b"
    num_nodes    = 1
    storage_type = "HDD"
  }
}
