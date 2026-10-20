# Two ways to test a module:
#   1. run it directly with a `module` block (the module becomes the thing under test)
#   2. replace it with override_module and test only the root logic around it
mock_provider "google" {
  source = "./tests/mocks"
}

variables {
  project_id = "jaylabs-lab003-demo"
}

run "module_one_subnet_per_entry" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    name   = "unit"
    region = "europe-west1"
    subnets = {
      app  = { cidr = "10.30.1.0/24" }
      data = { cidr = "10.30.2.0/24" }
      jobs = { cidr = "10.30.3.0/24" }
    }
    ssh_source_ranges = ["35.235.240.0/20"]
  }

  assert {
    condition     = length(google_compute_subnetwork.this) == 3
    error_message = "Expected one subnet per map entry."
  }

  assert {
    condition     = alltrue([for s in google_compute_subnetwork.this : s.private_ip_google_access && s.region == "europe-west1"])
    error_message = "Every subnet: Private Google Access on, in the module region."
  }

  assert {
    condition     = toset(output.internal_source_ranges) == toset(["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"])
    error_message = "allow-internal must cover exactly the subnet ranges."
  }

  assert {
    condition     = google_compute_firewall.allow_ssh.target_tags == toset(["ssh"])
    error_message = "SSH rule must only target instances tagged ssh."
  }

  assert {
    condition     = google_compute_network.this.auto_create_subnetworks == false
    error_message = "Custom-mode VPC only."
  }
}

run "module_rejects_ssh_from_anywhere" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    name              = "unit"
    region            = "europe-west1"
    subnets           = { app = { cidr = "10.30.1.0/24" } }
    ssh_source_ranges = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_source_ranges]
}

run "module_rejects_bad_cidr" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    name              = "unit"
    region            = "europe-west1"
    subnets           = { app = { cidr = "10.30.1.0/33" } }
    ssh_source_ranges = ["35.235.240.0/20"]
  }

  expect_failures = [var.subnets]
}

run "root_with_network_overridden" {
  command = plan

  # The network module is not planned at all: these outputs are used instead
  override_module {
    target = module.network
    outputs = {
      network_name      = "fake-vpc"
      network_self_link = "https://www.googleapis.com/compute/v1/projects/jaylabs-lab003-demo/global/networks/fake-vpc"
      subnet_self_links = {
        app = "https://www.googleapis.com/compute/v1/projects/jaylabs-lab003-demo/regions/europe-west1/subnetworks/fake-app"
      }
      subnet_cidrs = { app = "10.99.0.0/24" }
    }
  }

  assert {
    condition     = google_compute_instance.app.network_interface[0].subnetwork == "https://www.googleapis.com/compute/v1/projects/jaylabs-lab003-demo/regions/europe-west1/subnetworks/fake-app"
    error_message = "The instance must be placed in the module's app subnet."
  }

  assert {
    condition     = output.network_name == "fake-vpc"
    error_message = "network_name must come from the network module."
  }
}
