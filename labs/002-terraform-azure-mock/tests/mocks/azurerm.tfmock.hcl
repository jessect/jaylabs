# Shared mock data for every test file: mock_provider "azurerm" { source = "./tests/mocks" }
#
# Mocked computed values are random 8-character strings by default.
# Anything the provider validates as a UUID (tenant_id, object_id, principal_id)
# or that our code parses must get a realistic fixed value here.

mock_data "azurerm_client_config" {
  defaults = {
    tenant_id       = "00000000-0000-0000-0000-000000000001"
    object_id       = "00000000-0000-0000-0000-000000000002"
    subscription_id = "00000000-0000-0000-0000-000000000003"
  }
}

# In apply mode every computed id is invented by the mock. The provider parses
# ids it receives (storage_account_id, subnet_id, scope, ...), so random strings
# fail with "parsing the StorageAccount ID: the number of segments didn't match".
# Give each type a well-formed Azure resource id instead.

mock_resource "azurerm_resource_group" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock"
  }
}

mock_resource "azurerm_storage_account" {
  defaults = {
    id                    = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock/providers/Microsoft.Storage/storageAccounts/stmock"
    primary_blob_endpoint = "https://stmock.blob.core.windows.net/"
  }
}

mock_resource "azurerm_virtual_network" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
  }
}

mock_resource "azurerm_subnet" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
  }
}

mock_resource "azurerm_network_security_group" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
  }
}

mock_resource "azurerm_service_plan" {
  defaults = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock/providers/Microsoft.Web/serverFarms/asp-mock"
  }
}

mock_resource "azurerm_key_vault" {
  defaults = {
    id        = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
    vault_uri = "https://kv-mock.vault.azure.net/"
  }
}
