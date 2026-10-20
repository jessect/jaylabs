# Bad input must be rejected before anything reaches Azure.
# expect_failures turns "this run fails" into "this run passes",
# but only if the failure comes from the object you list.

mock_provider "azurerm" {
  source = "./tests/mocks"
}

run "rejects_uppercase_project" {
  command = plan

  variables {
    project = "JayLabs"
  }

  expect_failures = [var.project]
}

run "rejects_long_project" {
  command = plan

  variables {
    project = "jaylabsplatform" # 15 chars: storage account name would exceed 24
  }

  expect_failures = [var.project]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}

run "rejects_bad_cidrs" {
  command = plan

  variables {
    address_space       = "10.20.0.0/33"
    allowed_https_cidrs = ["203.0.113.7"] # missing /mask
  }

  expect_failures = [
    var.address_space,
    var.allowed_https_cidrs,
  ]
}

run "rejects_unsupported_sku" {
  command = plan

  variables {
    app_service_sku = "F1"
  }

  expect_failures = [var.app_service_sku]
}

# A lifecycle precondition, not a variable validation: prod on a Basic plan.
run "prod_rejects_basic_plan" {
  command = plan

  variables {
    environment     = "prod"
    app_service_sku = "B1"
  }

  expect_failures = [azurerm_linux_web_app.this]
}
