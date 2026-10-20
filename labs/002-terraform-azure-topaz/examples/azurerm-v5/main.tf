terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0" # the latest major: NOT what Topaz is tested with
    }
  }
}

# Same Topaz settings as the main lab, only the provider version changes.
provider "azurerm" {
  features {}
  metadata_host                   = "topaz.local.dev:8899"
  subscription_id                 = "00000000-0000-0000-0000-000000000001"
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-jaylabs-lab002-v5"
  location = "westeurope"
}

resource "azurerm_storage_account" "this" {
  name                     = "stjaylabslab002v5"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
