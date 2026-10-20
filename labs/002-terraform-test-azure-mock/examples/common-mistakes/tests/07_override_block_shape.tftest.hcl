# A nested block (identity) is overridden with an object, not a list.
# Error: Terraform expected an object type for attribute ".identity[0]" ... but found tuple.
mock_provider "azurerm" {
  source = "../../tests/mocks"
}

override_resource {
  target = azurerm_linux_web_app.this
  values = {
    identity = [{
      principal_id = "11111111-1111-1111-1111-111111111111"
    }]
  }
}

run "override_identity_as_list" {
  module {
    source = "../.."
  }
}
