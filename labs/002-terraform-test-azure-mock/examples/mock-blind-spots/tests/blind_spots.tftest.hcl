# Every run here PASSES. That is the point: each one would FAIL on real Azure.
# A mock knows the provider schema, not Azure itself.

mock_provider "azurerm" {
  source = "../../tests/mocks"
}

run "region_that_does_not_exist" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    location = "mars-north-1" # real Azure: LocationNotAvailableForResourceGroup
  }

  assert {
    condition     = output.resource_group_name == "rg-jaylabs-dev"
    error_message = "unexpected name"
  }
}

run "subnet_too_small" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    address_space = "10.20.0.0/24" # cidrsubnet(/24, 8, 1) = a /32 subnet. Real Azure: the smallest subnet is /29, App Service needs /28
  }

  assert {
    condition     = azurerm_subnet.app.address_prefixes[0] == "10.20.0.1/32"
    error_message = "unexpected subnet"
  }
}
