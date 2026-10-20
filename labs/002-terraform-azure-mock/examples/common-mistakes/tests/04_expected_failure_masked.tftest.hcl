# The precondition we want to see never runs: an unrelated error (random
# tenant_id) stops the plan first.
# Error: Missing expected failure
mock_provider "azurerm" {}

run "prod_rejects_basic_plan" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    environment     = "prod"
    app_service_sku = "B1"
  }

  expect_failures = [azurerm_linux_web_app.this]
}
