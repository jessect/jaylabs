# What the provider is configured with (project, region). Mocked in tests.
data "google_client_config" "current" {}

locals {
  name    = "${var.name_prefix}-${var.environment}"
  region  = data.google_client_config.current.region
  is_prod = var.environment == "prod"

  # prod always gets a database; other environments only when asked
  create_database = local.is_prod || var.enable_database

  labels = {
    lab         = "003"
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "network" {
  source = "./modules/network"

  name              = local.name
  region            = local.region
  subnets           = var.subnets
  ssh_source_ranges = var.ssh_source_ranges
}
