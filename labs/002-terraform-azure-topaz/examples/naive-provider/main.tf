terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.67.0"
    }
  }
}

# The provider block from every Azure tutorial: no metadata_host.
# azurerm uses the public cloud (management.azure.com, login.microsoftonline.com)
# and whatever account your Azure CLI is logged in to.
provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000001"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-jaylabs-lab002-naive"
  location = "westeurope"
}
