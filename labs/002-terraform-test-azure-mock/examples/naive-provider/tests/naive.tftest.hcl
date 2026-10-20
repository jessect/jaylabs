# No mock_provider here: `terraform test` configures the REAL azurerm provider,
# which tries to log in to Azure before it can even plan.
run "resource_group_name" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "rg-jaylabs-naive"
    error_message = "unexpected resource group name"
  }
}
