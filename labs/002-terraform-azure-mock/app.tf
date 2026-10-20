resource "azurerm_service_plan" "this" {
  name                = "asp-${local.suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = local.tags
}

resource "azurerm_linux_web_app" "this" {
  name                      = "app-${local.suffix}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  service_plan_id           = azurerm_service_plan.this.id
  https_only                = true
  virtual_network_subnet_id = azurerm_subnet.app.id
  tags                      = local.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"

    application_stack {
      node_version = "22-lts"
    }
  }

  app_settings = {
    STORAGE_ACCOUNT = azurerm_storage_account.this.name
    # Key Vault reference: App Service resolves it at runtime with its managed identity.
    DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.versionless_id})"
  }

  lifecycle {
    precondition {
      condition     = var.environment != "prod" || !startswith(var.app_service_sku, "B")
      error_message = "prod must not run on a Basic (B*) App Service plan: use S1, P0v3 or P1v3."
    }
  }
}
