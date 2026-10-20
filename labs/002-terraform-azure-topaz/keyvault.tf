# Who is running Terraform: the Topaz user from `make login`.
data "azurerm_client_config" "current" {}

# RBAC vault: even its creator needs a data-plane role. Grant it at subscription
# scope *before* the vault exists, because azurerm reads the vault's data plane
# while creating it (see README, error 5).
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope        = "/subscriptions/${var.subscription_id}"
  principal_id = data.azurerm_client_config.current.object_id

  # Built-in "Key Vault Administrator" by its fixed id (same GUID in every tenant).
  # Topaz cannot look roles up by name at resource-group scope (README, error 6).
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483"
}

resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.project}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7

  depends_on = [azurerm_role_assignment.deployer_kv_admin]
}

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "db" {
  name         = "db-password"
  value        = random_password.db.result
  key_vault_id = azurerm_key_vault.this.id
}
