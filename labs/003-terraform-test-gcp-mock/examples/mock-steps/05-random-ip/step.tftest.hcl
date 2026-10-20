# Step 5: the shared mocks, minus the VM's network_ip. Assert it is an IP.
mock_provider "google" {
  source = "./tests/mocks"

  # Replaces the shared mock_resource for the VM: no network_ip this time
  mock_resource "google_compute_instance" {}
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "dev_apply" {
  command = apply

  assert {
    condition     = can(cidrhost("${output.instance_internal_ip}/32", 0))
    error_message = "instance_internal_ip is not an IP address: ${output.instance_internal_ip}"
  }
}
