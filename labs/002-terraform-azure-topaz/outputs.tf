output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "storage_account" {
  value = azurerm_storage_account.this.name
}

output "blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "servicebus_namespace" {
  value = azurerm_servicebus_namespace.this.name
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "log_analytics_workspace" {
  value = azurerm_log_analytics_workspace.this.name
}
