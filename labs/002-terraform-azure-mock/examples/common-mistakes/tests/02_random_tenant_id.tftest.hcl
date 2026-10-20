# A bare mock: every computed value is a random 8-character string.
# Error: expected "tenant_id" to be a valid UUID, got <random>
mock_provider "azurerm" {}

run "plan_with_bare_mock" {
  command = plan

  module {
    source = "../.."
  }
}
