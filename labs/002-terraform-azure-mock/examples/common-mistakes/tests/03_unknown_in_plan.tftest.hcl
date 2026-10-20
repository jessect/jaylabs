# Ids only exist after apply. In a plan-mode run they are unknown.
# Error: Unknown condition value
mock_provider "azurerm" {
  source = "../../tests/mocks"
}

run "assert_on_id_in_plan" {
  command = plan

  module {
    source = "../.."
  }

  assert {
    condition     = azurerm_storage_account.this.id != ""
    error_message = "storage account must have an id"
  }
}
