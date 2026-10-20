terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Pinned: the version Topaz is tested with. azurerm 5.x calls a storage
      # API Topaz does not emulate yet (see README, error 3).
      version = "= 4.67.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}

  # The whole trick: fetch the cloud endpoints from Topaz instead of Azure.
  # Host and port only, no https:// (see README, error 4).
  metadata_host = var.metadata_host

  # The fixed subscription Topaz creates at start (--default-subscription).
  subscription_id = var.subscription_id

  # Topaz does not emulate resource provider registration.
  resource_provider_registrations = "none"

  # Auth: the Azure CLI session from `make login` (fake Topaz user, no real Azure account).
}
