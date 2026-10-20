terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

# The provider block most people write first. azurerm requires `features {}`.
provider "azurerm" {}

resource "azurerm_resource_group" "this" {
  name     = "rg-jaylabs-naive"
  location = "westeurope"
}
