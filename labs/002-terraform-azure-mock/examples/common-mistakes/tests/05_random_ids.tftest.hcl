# Apply mode with only the client config mocked: every resource id is random,
# and the provider refuses to parse them.
# Error: parsing "<random>": parsing the StorageAccount ID: the number of segments didn't match
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
      object_id = "00000000-0000-0000-0000-000000000002"
    }
  }
}

run "apply_with_random_ids" {
  module {
    source = "../.."
  }
}
