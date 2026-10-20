terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# The real provider block. It is never configured during `terraform test`:
# every test file replaces it with `mock_provider "azurerm"`, so no Azure
# login, subscription or network call is needed.
provider "azurerm" {
  features {}
}
